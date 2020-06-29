// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./DeedRepository.sol";

// solidity document style (Natspec)
// https://medium.com/@jeancvllr/solidity-tutorial-all-about-comments-bc31c729975a

/**
 * @title Auction Repository
 * This contracts allows auctions to be created for non-fungible tokens
 * Moreover, it includes the basic functionalities of an auction house
 */
contract AuctionRepository {
    // Array with all auctions
    Auction[] public auctions;
    // Mapping from auction index to user bids
    mapping(uint256 => Bid[]) public auctionBids;
    // Mapping from owner to a list of owned auctions
    mapping(address => uint256[]) public auctionOwner;

    // Bid struct to hold bidder and amount
    struct Bid {
        address payable from;
        uint256 amount;
    }

    // Auction struct which holds all the required info
    struct Auction {
        string name;
        // uint256 from 0 to 2^256-1
        uint256 blockDeadline;
        uint256 startPrice;
        string metadata;
        uint256 deedId;
        address deedRepositoryAddress;
        address owner;
        bool active;
        bool finalized;
    }

    /**
     * @dev Guarantees msg.sender is owner of the given auction
     * @param _auctionId uint256 ID of the auction to validate its ownership belongs to msg.sender
     */
    modifier isOwner(uint256 _auctionId) {
        require(auctions[_auctionId].owner == msg.sender, "must be owner");
        _;
    }

    /**
     * @dev Guarantees this contract is owner of the given deed/token
     * @param _deedRepositoryAddress address of the deed repository to validate from
     * @param _deedId uint256 ID of the deed which has been registered in the deed repository
     */
    modifier contractIsDeedOwner(
        address _deedRepositoryAddress,
        uint256 _deedId
    ) {
        // ownerOf is a function defined by ERC721
        // function ownerOf(uint256 tokenId) public view override returns (address) {
        address deedOwner = DeedRepository(_deedRepositoryAddress).ownerOf(
            _deedId
        );
        require(deedOwner == address(this), "contract must be deed owner");
        _;
    }

    /**
     * @dev Disallow payments to this contract directly
     */
    receive() external payable {
        revert();
    }

    /**
     * @dev Gets the length of auctions
     * @return uint256 representing the auction count
     */
    function getCount() public view returns (uint256) {
        return auctions.length;
    }

    /**
     * @dev Gets the bid counts of a given auction
     * @param _auctionId uint256 ID of the auction
     */
    function getBidsCount(uint256 _auctionId) public view returns (uint256) {
        return auctionBids[_auctionId].length;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _owner address of the auction owner
     */
    function getAuctionsOf(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return auctionOwner[_owner];
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _auctionId uint256 of the auction owner
     * @return amount uint256, address of last bidder
     */
    function getCurrentBid(uint256 _auctionId)
        public
        view
        returns (uint256, address)
    {
        uint256 bidsLength = auctionBids[_auctionId].length;
        // if there are bids refund the last bid
        if (bidsLength > 0) {
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.amount, lastBid.from);
        }
        return (0, address(0));
    }

    /**
     * @dev Gets the total number of auctions owned by an address
     * @param _owner address of the owner
     * @return uint256 total number of auctions
     */
    function getAuctionsCountOfOwner(address _owner)
        public
        view
        returns (uint256)
    {
        return auctionOwner[_owner].length;
    }

    /**
     * @dev Gets the info of a given auction which are stored within a struct
     * @param _auctionId uint256 ID of the auction
     * @return name string name of the auction
     * @return blockDeadline uint256 timestamp of the auction in which it expires
     * @return startPrice uint256 starting price of the auction
     * @return metadata string metadata representing the metadata of the auction
     * @return deedId uint256 deedId ID of the deed registered in DeedRepository
     * @return deedRepositoryAddress address Address of the DeedRepository
     * @return owner address owner of the auction
     * @return active bool whether the auction is active
     * @return finalized bool whether the auction is finalized
     */
    function getAuctionById(uint256 _auctionId)
        public
        view
        returns (
            string memory name,
            uint256 blockDeadline,
            uint256 startPrice,
            string memory metadata,
            uint256 deedId,
            address deedRepositoryAddress,
            address owner,
            bool active,
            bool finalized
        )
    {
        Auction memory auc = auctions[_auctionId];
        return (
            auc.name,
            auc.blockDeadline,
            auc.startPrice,
            auc.metadata,
            auc.deedId,
            auc.deedRepositoryAddress,
            auc.owner,
            auc.active,
            auc.finalized
        );
    }

    /**
     * @dev Creates an auction with the given informatin
     * @param _deedRepositoryAddress address of the DeedRepository contract
     * @param _deedId uint256 of the deed registered in DeedRepository
     * @param _auctionTitle string containing auction title
     * @param _metadata string containing auction metadata
     * @param _startPrice uint256 starting price of the auction
     * @param _blockDeadline uint is the timestamp in which the auction expires
     * @return bool whether the auction is created
     */
    function createAuction(
        address _deedRepositoryAddress,
        uint256 _deedId,
        string memory _auctionTitle,
        string memory _metadata,
        uint256 _startPrice,
        uint256 _blockDeadline
    )
        public
        contractIsDeedOwner(_deedRepositoryAddress, _deedId)
        returns (bool)
    {
        uint256 auctionId = auctions.length;
        Auction memory newAuction;
        newAuction.name = _auctionTitle;
        newAuction.blockDeadline = _blockDeadline;
        newAuction.startPrice = _startPrice;
        newAuction.metadata = _metadata;
        newAuction.deedId = _deedId;
        newAuction.deedRepositoryAddress = _deedRepositoryAddress;
        newAuction.owner = msg.sender;
        newAuction.active = true;
        newAuction.finalized = false;

        auctions.push(newAuction);
        auctionOwner[msg.sender].push(auctionId);

        emit AuctionCreated(msg.sender, auctionId);
        return true;
    }

    function approveAndTransfer(
        address _from,
        address _to,
        address _deedRepositoryAddress,
        uint256 _deedId
    ) internal returns (bool) {
        DeedRepository remoteContract = DeedRepository(_deedRepositoryAddress);
        remoteContract.approve(_to, _deedId);
        remoteContract.transferFrom(_from, _to, _deedId);
        return true;
    }

    /**
     * @dev Cancels an ongoing auction by the owner
     * @dev Deed is transfered back to the auction owner
     * @dev Bidder is refunded with the initial amount
     * @param _auctionId uint ID of the created auction
     */
    function cancelAuction(uint256 _auctionId) public isOwner(_auctionId) {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;
        // if there are bids refund the last bid
        if (bidsLength > 0) {
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            // send vs transfer
            // https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage
            // https://ethereum.stackexchange.com/questions/82412/using-value-is-deprecated-use-value-instead
            // https://vomtom.at/solidity-0-6-4-and-call-value-curly-brackets/
            (bool success, ) = lastBid.from.call{value: lastBid.amount}("");
            // require, assert and revert
            // https://ethereum.stackexchange.com/questions/15166/difference-between-require-and-assert-and-the-difference-between-revert-and-thro
            // https://medium.com/blockchannel/the-use-of-revert-assert-and-require-in-solidity-and-the-new-revert-opcode-in-the-evm-1a3a7990e06e
            require(success, "Failed to transfer the funds, aborting");
        }

        // approve and transfer from this contract to auction owner
        if (
            approveAndTransfer(
                address(this),
                myAuction.owner,
                myAuction.deedRepositoryAddress,
                myAuction.deedId
            )
        ) {
            auctions[_auctionId].active = false;
            emit AuctionCanceled(msg.sender, _auctionId);
        }
    }

    /**
     * @dev Finalized an ended auction
     * @dev The auction should be ended, and there should be at least one bid
     * @dev On success Deed is transfered to bidder and auction owner gets the amount
     * @param _auctionId uint ID of the created auction
     */
    function finalizeAuction(uint256 _auctionId) public {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;

        // 1. if auction not ended just revert
        if (block.timestamp < myAuction.blockDeadline) revert();

        // if there are no bids cancel
        if (bidsLength == 0) {
            cancelAuction(_auctionId);
        } else {
            // 2. the money goes to the auction owner
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            (bool success, ) = lastBid.from.call{value: lastBid.amount}("");
            require(success, "Failed to transfer the funds, aborting");

            // approve and transfer from this contract to the bid winner
            if (
                approveAndTransfer(
                    address(this),
                    lastBid.from,
                    myAuction.deedRepositoryAddress,
                    myAuction.deedId
                )
            ) {
                auctions[_auctionId].active = false;
                auctions[_auctionId].finalized = true;
                emit AuctionFinalized(msg.sender, _auctionId);
            }
        }
    }

    /**
     * @dev Bidder sends bid on an auction
     * @dev Auction should be active and not ended
     * @dev Refund previous bidder if a new bid is valid and placed.
     * @param _auctionId uint ID of the created auction
     */
    function bidOnAuction(uint256 _auctionId) external payable {
        uint256 ethAmountSent = msg.value;

        // owner can't bid on their auctions
        Auction memory myAuction = auctions[_auctionId];
        if (myAuction.owner == msg.sender) revert();

        // if auction is expired
        if (block.timestamp > myAuction.blockDeadline) revert();

        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        Bid memory lastBid;

        // there are previous bids
        if (bidsLength > 0) {
            lastBid = auctionBids[_auctionId][bidsLength - 1];
            tempAmount = lastBid.amount;
        }

        // check if amount is greater than previous amount
        if (ethAmountSent < tempAmount) revert();

        // refund the last bidder
        // be careful of reentrancy attack!
        if (bidsLength > 0) {
            (bool success, ) = lastBid.from.call{value: lastBid.amount}("");
            require(success, "Failed to transfer the funds, aborting");
        }

        // insert bid
        Bid memory newBid;
        newBid.from = msg.sender;
        newBid.amount = ethAmountSent;
        auctionBids[_auctionId].push(newBid);
        emit BidSuccess(msg.sender, _auctionId);
    }

    // BidSuccess is fired when a bid is received
    event BidSuccess(address _from, uint256 _auctionId);

    // AuctionCreated is fired when an auction is created
    event AuctionCreated(address _owner, uint256 _auctionId);

    // AuctionCanceled is fired when an auction is canceled
    event AuctionCanceled(address _owner, uint256 _auctionId);

    // AuctionFinalized is fired when an auction is finalized
    event AuctionFinalized(address _owner, uint256 _auctionId);
}
