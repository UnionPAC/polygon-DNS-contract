// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

import { StringUtils } from "./libraries/StringUtils.sol";
import { Base64 } from "./libraries/Base64.sol";

contract Domains is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public owner;
    string public tld;

    // Start and End of SVG element
    string svgStart = 
    '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><defs><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path fill="#fcea2b" stroke="#fcea2b" stroke-miterlimit="10" stroke-width="2" d="M62.458 33.306a8.039 8.039 0 0 1 1.908 1.234c3.84 3.146 6.78 7.653 6.784 12.756a17.977 17.977 0 0 1-3.284 9.753A27.03 27.03 0 0 1 57.398 66.3c-3.381 1.679-7.18 2.687-10.021 5.169-2.686 2.348-4.552 6.004-8.016 6.852a8.077 8.077 0 0 1-5.054-.634c-14.821-6.4-8.631-29.073.276-37.63l.029-.03a27.44 27.44 0 0 1 14.372-7.008c3.89-.677 9.708-1.3 13.475.287Z"/><path fill="#f1b31c" stroke="#f1b31c" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M71.099 47.287c-.004-5.104-2.943-9.61-6.783-12.756a8.514 8.514 0 0 0-1.727-1.145 15.522 15.522 0 0 1 3.881 9.882 17.978 17.978 0 0 1-3.283 9.753 27.032 27.032 0 0 1-10.47 9.251c-3.38 1.68-7.178 2.687-10.02 5.17-2.686 2.347-4.551 6.003-8.015 6.851a8.076 8.076 0 0 1-5.055-.634 15.787 15.787 0 0 1-1.256-.611 13.979 13.979 0 0 0 5.885 4.63 8.076 8.076 0 0 0 5.054.634c3.465-.848 5.33-4.504 8.016-6.851 2.841-2.483 6.64-3.492 10.02-5.17a27.032 27.032 0 0 0 10.47-9.251 17.977 17.977 0 0 0 3.284-9.753Z"/><path fill="#b1cc33" d="M57.403 30.725s-4.904 5.363-10.696 6.14-12.224-2.847-12.224-2.847 4.905-5.363 10.697-6.14 12.223 2.847 12.223 2.847Z"/><g stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M64.534 34.569c3.936 3.163 6.956 7.684 6.98 12.79a17.627 17.627 0 0 1-3.317 9.748 27.142 27.142 0 0 1-10.66 9.218c-3.447 1.667-7.325 2.66-10.392 6.118-2.735 2.34-4.626 5.991-8.163 6.827a8.43 8.43 0 0 1-5.165-.654c-14.995-7.445-8.757-30.11.31-38.64l.03-.029a21.53 21.53 0 0 1 5.02-3.757m19.724-8.2-.955 5.417"/><path d="M57.403 30.725s-4.904 5.363-10.696 6.14-12.224-2.847-12.224-2.847 4.905-5.363 10.697-6.14 12.223 2.847 12.223 2.847Z"/></g><defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#FFFB7D"/><stop offset="1" stop-color="#85FFBD" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#b)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';

    string svgEnd = '</text></svg>';

    // store domain names linked to addresses
    mapping(string => address) public domains;

    // store records linked to domain names
    mapping(string => string) public records;

    // store names linked to their address
    mapping(uint => string) public names;

    // Custom Errors
    error Unauthorized();
    error AlreadyRegistered();
    error InvalidName(string name);

    constructor(string memory _tld) payable ERC721("Mango Name Service", "MNS") {
        owner = payable(msg.sender);
        tld = _tld;
        console.log("%s name service deployed!", _tld);
    }

    modifier onlyOwner() {
        require(isOwner());
         _;
    }

    // will give us the price of a domain based on it's length
    function price(string calldata name) public pure returns (uint) {
        // get the length of the given _name
        uint length = StringUtils.strlen(name);
        require(length > 0, "name must not be blank");
        // if name is 1 to 3 characters, the price will be 0.5 MATIC
        if (length <= 3) {
            return 5 * 10**17;
        // if name is 4 characters, the price will be 0.3 MATIC
        } else if (length == 4) {
            return 3 * 10**17;
        // if name is more than 4 characters, the price will be 0.1 MATIC
        } else {
            return 1 * 10*17;
        }
    }

    // requires domain names to be between 3 and 8 characters
    function valid(string calldata name) public pure returns(bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 8;
    }

    function register(string calldata name) public payable {
        // check if name has already been registered, if it equals address zero it hasn't been registered
        // require(domains[name] == address(0));
        if(domains[name] != address(0)) revert AlreadyRegistered();
        if(!valid(name)) revert InvalidName(name);

        // get the price of the name based on its character length
        uint256 _price = price(name);
        require(msg.value >= _price, "Not enough MATIC given");

        string memory _name = string(abi.encodePacked(name, ".", tld));
        string memory finalSvg = string(abi.encodePacked(svgStart, _name, svgEnd));
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A domain on the Mango Name Service", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                strLen,
                '"}'
            )
        );

        string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));
        console.log("\n--------------------------------------------------------");
        console.log("Final tokenURI", finalTokenUri);
        console.log("--------------------------------------------------------\n");

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;

        names[newRecordId] = name;
        _tokenIds.increment();
    }

    function setRecord(string calldata name, string calldata record) public {
        // check that the domain owner is the msg.sender
        // require(domains[name] == msg.sender);
        if(msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name) public view returns (string memory) {
        return records[name];
    }

    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function getAllNames() public view returns (string[] memory allNames) {
        console.log('Getting all domain names from the contract');
        allNames = new string[](_tokenIds.current());
        for (uint i = 0; i < _tokenIds.current() ; i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }
        return allNames;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
  
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw funds!");
    } 

}