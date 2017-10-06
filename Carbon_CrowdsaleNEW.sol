pragma solidity ^ 0.4.8;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "github.com/Arachnid/solidity-stringutils/strings.sol";

import "./CarbonTOKEN.sol";

contract Carbon_Crowdsale is usingOraclize {
    CarbonTOKEN token_contract;

    using strings
    for * ;

    uint256 token_price = 100; //assumed preICO price token price is 1 dollars per token here value taken is in cents, 
    bool pre_Sale = true;

    //ico startdate enddate;
    uint256 startdate;
    uint256 enddate;

    uint decimals = 4;
    uint public lastprice;
    string public lastpriceString;
    mapping(bytes32=>bool) validIds;

    //flag to indicate whether ICO is paused or not
    bool public stopped = false;

    address owner;

    uint public totalEtherRaised;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    event Transfer(address indexed to, uint value);

    event No_Of_Token(uint tokens);


    mapping(bytes32 => address) userAddress; // mapping to store user address
    mapping(address => uint) uservalue; // mapping to store user value
    mapping(bytes32 => bytes32) userqueryID; // mapping to store user oracalize query id

    // called by the owner on emergency, pause ICO
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

    // called by the owner on end of emergency, resumes ICO
    function release() external onlyOwner {
        stopped = false;
    }

    function Carbon_Crowdsale(address _token) {
        owner = msg.sender;
        token_contract = CarbonTOKEN(_token);
         // oraclize_setCustomGasPrice(4000000000 wei);
         oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
   }

    // start crowdsale/ico by calling this function 
    //owner will call this function on 16th september to start crowdsale
    function start_ICO() public onlyOwner {
        pre_Sale = false;
        stopped = false;
        token_price = 200; // token price 2 USD after starting ICO from 16 september 
        startdate = now;
        enddate = startdate + 30 days; // end day is 15 october so number of days is 30

    }

    // unnamed function whenever any one sends ether to this smart contract address it wil fall in this
    //function which is payable
    function() payable {
        if (!stopped) {
            if (pre_Sale && msg.sender != owner) {
                bytes32 ID2 = oraclize_query("URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
                userAddress[ID2] = msg.sender;
                uservalue[msg.sender] = msg.value;

                userqueryID[ID2] = ID2;
                validIds[ID2] = true;
            } else if (!pre_Sale) {
                if (msg.sender != owner && now >= startdate && now <= enddate) {
                    bytes32 ID = oraclize_query("URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
                    userAddress[ID] = msg.sender;
                    uservalue[msg.sender] = msg.value;
                    userqueryID[ID] = ID;
                    validIds[ID] = true;
                } else if (msg.sender != owner && now > enddate) {
                    revert();
                }

            }

        } else {
            revert();
        }

    }

    // end ICO sholud be called by owner after ico end date
    function end_crowdsale() public onlyOwner {
        stopped = true;
    }
   
    // callback function of oracalize which is called when oracalize query return result
    function __callback(bytes32 myid, string result, bytes proof) {
        if (!validIds[myid]) revert();
        if (msg.sender != oraclize_cbAddress()) {
            // just to be sure the calling address is the Oraclize authorized one
            revert();
        }

        lastpriceString = result;
        if (userqueryID[myid] == myid) {

            var s = result.toSlice();

            strings.slice memory part;
            uint finanl_price_ = stringToUint(s.split(".".toSlice()).toString());
            lastprice = finanl_price_;
            // uint finanl_price_ = stringToUint(usd_price_a.toString());
           
            uint no_of_token = ((finanl_price_ * uservalue[userAddress[myid]]) * 10 ** decimals) / (token_price *
                10 ** 16);
            No_Of_Token(no_of_token);
            if (token_contract.balanceOf(address(this)) > no_of_token) {
                token_contract.transferCoins(userAddress[myid], no_of_token); // carbon Tokens come from ICO
                Transfer(userAddress[myid], no_of_token);
           }
          
        }
         delete validIds[myid];
    }

    //Below function will convert string to integer removing decimal
    function stringToUint(string s) private constant returns(uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);

            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
                // usd_price=res2ult;
            }
        }
    }

    //Drain Any Ether in Crowdsale to owner
    function drain() public onlyOwner {
        owner.transfer(this.balance);
    }

    //Drain carbon tokens to Owner prior/after to ICO
    function drainCarbonToken() public onlyOwner {
        if (token_contract.balanceOf(address(this)) > 0)
       token_contract.transferCoins(owner,token_contract.balanceOf(address(this)));
      }
      
     function transferOwnership(address newOwner) onlyOwner {
      owner = newOwner;
      
    }

}