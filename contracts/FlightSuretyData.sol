pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    uint256 private constant REGISTRATION_FEE = 10 ether;
    uint8 private constant INITIAL_AIRLINES_NUM = 5;

    address private contractOwner; // Account used to deploy contract
    bool private operational = true;  
    uint256 private registeredAirlinesNum = 0;  

    struct Airline {
        address airlineAddress;
        //bool isRegistered;
        uint256 funds;
        address[] voters;
    }

    mapping (address => bool) private authorizedCallers; 
    mapping(address => Airline) private registeredAirlines;
    mapping(address => Airline) private candidatesAirlines;
    

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

    /**
    * @dev Modifier that requires the amount sent to activate a new airline to be at least equal with the registration fee 
    */
    modifier requireRegistrationFee()
    {
        require(msg.value >= REGISTRATION_FEE, "Amount sent is less than the registration fee");
        _;
    }

    modifier requireAirlineDeposit(address _airlineCaller) {
        require(registeredAirlines[_airlineCaller].funds >= REGISTRATION_FEE, "Airline has not paid the registration fee");
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
                                address _airlineCaller
                            )
                            requireIsOperational
                            requireCallerIsAuthorized
                            requireAirlineDeposit(_airlineCaller)
                            external
                           
    { 
        require(registeredAirlines[_airlineAddress].airlineAddress == 0);
        
        if(registeredAirlinesNum < INITIAL_AIRLINES_NUM) 
        {
            registeredAirlines[_airlineAddress] = Airline(_airlineAddress, 0, new address[](0));
        }else
        {
               // if the airline is a candidate
            if(candidatesAirlines[_airlineAddress].airlineAddress != 0)
            {
                    
            }else 
            {   // Add it as a candidate
                candidatesAirlines[_airlineAddress] = Airline(_airlineAddress, 0, new address[](5));
            }
        }
       
    }
    function getAirlinesNumber()public view  returns(uint256){return registeredAirlinesNum;}

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
        return registeredAirlines[_airlineAddress].airlineAddress != 0;
    }

    /**
    * @dev Check if an airline is candidate
    *
    */
    function isCandidate
                      (
                        address _airlineAddress
                       ) 
                       public 
                       view 
                       returns (bool)
    {
        return candidatesAirlines[_airlineAddress].airlineAddress != 0;
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
                                address _airlineAddress
                            )
                            external
                            payable
                            requireIsOperational
                            requireRegistrationFee
    {
        registeredAirlines[_airlineAddress].funds = registeredAirlines[_airlineAddress].funds.add(msg.value);
        registeredAirlinesNum = registeredAirlinesNum.add(1);
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
      // fund();
    }


}

