// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

pragma solidity >=0.5.0 <=0.7.4;
import "./Library.sol";

contract AssetTracker {
    // Asset mapping
    mapping(string => Library.Asset) AssetStore;

    // Failed Verification mapping and count
    mapping(uint => Library.Failure) public FailureStore;
    uint public FailureCount;

    // Identity mapping
    mapping(address => Library.Identity) IdentityStore;
    mapping(string => address) private IdentityLookup;

    // Arbitrator's address
    address public arbitrator;

    constructor (address _arbitrator) public {
        arbitrator = _arbitrator;
    }

    // Get Failure Count
    function getFailureCount() public view returns (uint256) {
        require(msg.sender == arbitrator,"You're not the arbitrator");
        return FailureCount;
    }

    // Get Failure
    function getFailure(uint _id) public view returns (string memory, string memory, string memory) {
        require(msg.sender == arbitrator,"You're not the arbitrator");
        return (FailureStore[_id].uid,IdentityStore[FailureStore[_id].owner].name,IdentityStore[FailureStore[_id].owner].email);
    }

    // Create Asset
    function createAsset(
        uint256 quantity,
        string memory _assetUid,
        string memory _random
    ) public returns (uint256) {
        require(
            IdentityStore[msg.sender].addr != address(0),
            "You Don't Have An Account!"
        );
        string memory accer = IdentityStore[msg.sender].position;
        require(
            keccak256(abi.encodePacked((accer))) ==
                keccak256(abi.encodePacked(("Manufacturer"))),
            "You're not a manufacturer!"
        );
        require(
            AssetStore[_assetUid].ownerAddress == address(0),
            "Try a different UID!"
        );
        string memory details = string(
            abi.encodePacked(
                IdentityStore[msg.sender].email,
                IdentityStore[msg.sender].name
            )
        );
        string memory acc = createKey(_random, _assetUid, details);
        IdentityStore[msg.sender].assetCount++;
        AssetStore[_assetUid] = Library.Asset(
            IdentityStore[msg.sender].assetCount,
            _assetUid,
            acc,
            msg.sender,
            true,
            true,
            quantity
        );
        IdentityStore[msg.sender].ownedAssets[IdentityStore[msg.sender]
            .assetCount] = AssetStore[_assetUid];
        emit AssetCreate(_assetUid, IdentityStore[msg.sender].email, quantity);
    }

    // Get Asset Key
    function getAssetKey(string memory _assetUid)
        public
        view
        returns (string memory)
    {
        require(
            IdentityStore[msg.sender].addr != address(0),
            "You Don't Have An Account!"
        );
        require(
            AssetStore[_assetUid].ownerAddress != address(0),
            "Asset does not exist!"
        );
        Library.Asset storage curr = AssetStore[_assetUid];
        require(curr.ownerAddress == msg.sender, "You're not the owner!");
        require(curr.isGenuine, "The asset isn't genuine!");
        require(curr.isVerified, "The asset isn't verified!");
        return curr.key;
    }

    // Split asset into two
    function splitAsset(
        string memory _assetUid,
        uint256 div,
        string memory _newAssetUid,
        string memory _random
    ) public returns (uint256) {
        require(
            IdentityStore[msg.sender].addr != address(0),
            "You Don't Have An Account!"
        );
        require(
            AssetStore[_assetUid].ownerAddress != address(0),
            "Asset does not exist!"
        );
        Library.Asset storage curr = AssetStore[_assetUid];
        require(curr.ownerAddress == msg.sender, "You're not the owner!");
        require(curr.isGenuine, "The asset isn't genuine!");
        require(curr.isVerified, "The asset isn't verified!");
        require(curr.quantity > div && div > 0, "Insufficient Assets");
        require(
            AssetStore[_newAssetUid].ownerAddress == address(0),
            "Try a different UID!"
        );
        uint256 ogQty = curr.quantity;
        AssetStore[_assetUid].quantity = ogQty - div;
        IdentityStore[msg.sender].ownedAssets[AssetStore[_assetUid].ownerFlag].quantity = ogQty - div;
        string memory details = string(
            abi.encodePacked(
                IdentityStore[msg.sender].email,
                IdentityStore[msg.sender].name
            )
        );
        string memory acc = createKey(_random, _newAssetUid, details);
        IdentityStore[msg.sender].assetCount++;
        AssetStore[_newAssetUid] = Library.Asset(
            IdentityStore[msg.sender].assetCount,
            _newAssetUid,
            acc,
            msg.sender,
            true,
            true,
            div
        );
        IdentityStore[msg.sender].ownedAssets[IdentityStore[msg.sender]
            .assetCount] = AssetStore[_newAssetUid];
        emit AssetSplit(
            _assetUid,
            _newAssetUid,
            IdentityStore[msg.sender].email,
            div
        );
    }

    // Verification of asset
    function verifyAsset(
        string memory _assetUid,
        string memory _key,
        string memory _random
    ) public returns (uint256) {
        require(
            IdentityStore[msg.sender].addr != address(0),
            "You Don't Have An Account!"
        );
        require(
            AssetStore[_assetUid].ownerAddress != address(0),
            "Asset does not exist!"
        );
        Library.Asset storage curr = AssetStore[_assetUid];
        require(curr.ownerAddress == msg.sender, "You're not the owner!");
        require(curr.isGenuine, "The asset isn't genuine!");
        string memory acc = AssetStore[_assetUid].key;
        string memory _ownerEmail = IdentityStore[msg.sender].email;
        if (
            keccak256(abi.encodePacked((acc))) ==
            keccak256(abi.encodePacked((_key)))
        ) {
            string memory _details = string(
                abi.encodePacked(
                    IdentityStore[msg.sender].email,
                    IdentityStore[msg.sender].name
                )
            );
            string memory keyer = createKey(_random, _assetUid, _details);
            IdentityStore[msg.sender].ownedAssets[AssetStore[_assetUid].ownerFlag].key = keyer;
            IdentityStore[msg.sender].ownedAssets[AssetStore[_assetUid].ownerFlag].isVerified = true;
            AssetStore[_assetUid].key = keyer;
            AssetStore[_assetUid].isVerified = true;
            emit AssetVerificationSuccessful(_ownerEmail, _assetUid);
        } else {
            IdentityStore[msg.sender].ownedAssets[AssetStore[_assetUid].ownerFlag].isGenuine = false;
            AssetStore[_assetUid].isGenuine = false;
            FailureCount++;
            FailureStore[FailureCount] = Library.Failure(FailureCount,msg.sender,_assetUid);
            emit AssetVerificationFailed(_ownerEmail, _assetUid);
        }
    }

    // Transfer ownership
    function transferOwnership(
        string memory _assetUid,
        string memory _receiverEmail
    ) public returns (uint256) {
        require(
            IdentityStore[msg.sender].addr != address(0),
            "You Don't Have An Account!"
        );
        require(
            keccak256(abi.encodePacked((IdentityStore[msg.sender].email))) != keccak256(abi.encodePacked((_receiverEmail))),
            "Cannot transfer ownership to yourself!"
        );
        require(
            AssetStore[_assetUid].ownerAddress != address(0),
            "Asset does not exist!"
        );
        require(
            IdentityLookup[_receiverEmail] != address(0),
            "This email does not exists!"
        );
        Library.Asset storage curr = AssetStore[_assetUid];
        require(curr.ownerAddress == msg.sender,"You are not the owner");
        require(curr.isGenuine, "The asset isn't genuine!");
        require(curr.isVerified, "The asset isn't verified!");
        string memory _senderEmail = IdentityStore[msg.sender].email;
        address acc = IdentityLookup[_receiverEmail];
        delete IdentityStore[msg.sender].ownedAssets[curr.ownerFlag];
        AssetStore[_assetUid].ownerAddress = acc;
        AssetStore[_assetUid].isVerified = false;
        IdentityStore[acc].assetCount++;
        AssetStore[_assetUid].ownerFlag = IdentityStore[acc].assetCount;
        IdentityStore[acc].ownedAssets[IdentityStore[acc]
            .assetCount] = AssetStore[_assetUid];
        emit AssetOwnershipTransfer(_senderEmail, _receiverEmail, _assetUid);
    }

    // Sell to end consumer
    function sellToEndConsumer(string memory _assetUid)
        public
        returns (uint256)
    {
        require(
            IdentityStore[msg.sender].addr != address(0),
            "You Don't Have An Account!"
        );
        require(
            AssetStore[_assetUid].ownerAddress != address(0),
            "Asset does not exist!"
        );
        string memory accer = IdentityStore[msg.sender].position;
        require(
            keccak256(abi.encodePacked((accer))) ==
                keccak256(abi.encodePacked(("Retailer"))),
            "You're not a retailer!"
        );
        Library.Asset storage curr = AssetStore[_assetUid];
        require(curr.ownerAddress == msg.sender, "You're not the owner!");
        string memory _sellerEmail = IdentityStore[msg.sender].email;
        delete IdentityStore[msg.sender].ownedAssets[curr.ownerFlag];
        delete AssetStore[_assetUid];
        emit SoldToEndConsumer(_assetUid, _sellerEmail);
    }

    // Sign-up function
    function createIdentity(
        string memory _name,
        string memory _email,
        string memory _password,
        string memory _position
    ) public returns (uint256) {
        require(
            IdentityLookup[_email] == address(0),
            "This email is already used!"
        );
        require(
            IdentityStore[msg.sender].addr == address(0),
            "You Already Have An Account!"
        );
        Library.Identity storage newIdentity = IdentityStore[msg.sender];
        newIdentity.name = _name;
        newIdentity.email = _email;
        newIdentity.password = _password;
        newIdentity.position = _position;
        newIdentity.addr = msg.sender;
        newIdentity.assetCount = 0;
        IdentityLookup[_email] = msg.sender;
        emit IdentityCreate(_name, _email, _position);
    }

    // Login function
    function logInIdentity(string memory _password) public returns (uint256) {
        require(
            IdentityStore[msg.sender].addr != address(0),
            "You Don't Have An Account!"
        );
        string memory acc = IdentityStore[msg.sender].password;
        require(
            keccak256(abi.encodePacked((acc))) ==
                keccak256(abi.encodePacked((_password))),
            "Invalid Password"
        );
        string memory _name = IdentityStore[msg.sender].name;
        string memory _email = IdentityStore[msg.sender].email;
        string memory _position = IdentityStore[msg.sender].position;
        emit IdentityLogin(_name, _email, _position);
    }

    // Create key for asset
    function createKey(
        string memory _random,
        string memory _assetUid,
        string memory _details
    ) internal view returns (string memory) {
        return uintToString(uint(keccak256(abi.encodePacked(_random, _assetUid, _details, block.number))));
    }

    // Get asset count of user
    function getUserAssetCount() public view returns (uint,string memory) {
        require(
            IdentityStore[msg.sender].addr != address(0),
            "You Don't Have An Account!"
        );
        return (IdentityStore[msg.sender].assetCount,IdentityStore[msg.sender].position);
    }

    // Get Assets of a user
    function getAsset(uint256 ind)
        public
        view
        returns (
            string memory,
            bool,
            bool,
            uint256
        )
    {
        require(
            IdentityStore[msg.sender].addr != address(0),
            "You Don't Have An Account!"
        );
        if (
            IdentityStore[msg.sender].ownedAssets[ind].ownerAddress ==
            msg.sender
        ) {
            return (
                IdentityStore[msg.sender].ownedAssets[ind].assetUid,
                IdentityStore[msg.sender].ownedAssets[ind].isVerified,
                IdentityStore[msg.sender].ownedAssets[ind].isGenuine,
                IdentityStore[msg.sender].ownedAssets[ind].quantity
            );
        } else {
            return ("None", false, false, 0);
        }
    }

    // Uint to string
    function uintToString(uint _i) internal pure returns (string memory) {
        uint temp = _i;
        if (temp == 0) {
            return "0";
        }
        uint j = temp;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (temp != 0) {
            bstr[k--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(bstr);
    }

    // Asset sold to end consumer
    event SoldToEndConsumer(string assetUid, string sellerEmail);

    // Asset Verification Successful
    event AssetVerificationSuccessful(string ownerEmail, string assetUid);

    // Asset Verification Failed
    event AssetVerificationFailed(string ownerEmail, string assetUid);

    // Asset Ownership Transfer Event
    event AssetOwnershipTransfer(
        string senderEmail,
        string receiverEmail,
        string assetUid
    );

    // Asset Create Event
    event AssetCreate(string assetUid, string creatorEmail, uint256 qunatity);

    // Asset Create Event
    event AssetSplit(
        string assetUid,
        string newAssetUid,
        string creatorEmail,
        uint256 qunatity
    );

    // Sign-up Event
    event IdentityCreate(string name, string email, string position);

    // Login Event
    event IdentityLogin(string name, string email, string position);
}