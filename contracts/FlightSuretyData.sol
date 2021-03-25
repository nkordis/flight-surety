pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;  
    uint256 private approvedAirlinesCount = 0;                                  // Blocks all state changes throughout the contract if false

    struct Airline {
        address airlineAddress;
        bool isRegistered;
        uint256 funds;
        address[] voters;
    }

    mapping (address => bool) private authorizedCallers; 
    mapping(address => Airline) public registeredAirlines;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    
    /**
    * @dev Modifier that requires the caller of the function to be authorized
    */
    modifier requireCallerIsAuthorized()
    {
        require(authorizedCallers[msg.sender], "Caller is not authorized");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }


    /**
    * @dev Contract owner can authorize a caller to use the contract
    *
    * @param _caller The caller's address
    */  
    function authorizeCaller
                            (
                                address _caller
                            )
                            external
                            requireContractOwner 
    {
        authorizedCallers[_caller] = true;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address _airlineAddress,
                                address airlineCaller
                            )
                            requireIsOperational
                            requireCallerIsAuthorized
                            external
                           
    { 
        require(registeredAirlines[_airlineAddress].airlineAddress == 0);
        
        if(approvedAirlinesCount < 5) 
        {
            registeredAirlines[_airlineAddress] = Airline(_airlineAddress, true, 0, new address[](0));
        }
       
    }


    /**
    * @dev Check if an airline is registered
    *
    */
    function isAirline
                      (
                        address _airlineAddress
                       ) 
                       public 
                       view 
                       returns (bool)
    {
        return registeredAirlines[_airlineAddress].isRegistered;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                            
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

