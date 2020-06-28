// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// https://github.com/juanfranblanco/vscode-solidity/issues/70
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Katie is ERC721 {
    string[] public colors;
    mapping(string => bool) _colorExists;

    constructor() public ERC721("Katie", "KATE") {}

    function mint(string memory _color) public {
        // https://solidity.readthedocs.io/en/v0.6.2/060-breaking-changes.html
        // The function push(value) for dynamic storage arrays does not return the new length anymore (it returns nothing)
        require(!_colorExists[_color], "color already exists");
        colors.push(_color);
        _mint(msg.sender, colors.length);
        _colorExists[_color] = true;
    }
}
