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
        uint256 funds;
        address[] voters;
    }

    struct Passenger {
        uint256 deposit;
        uint256 payout;
    }

    struct Flight {
        string flightName;
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
        address[] passengersInsurances;
    }
    
    bytes32[] private flightKeys; 

    mapping (address => bool) private authorizedCallers; 
    mapping(address => Airline) private registeredAirlines;
    mapping(address => Airline) private candidatesAirlines;
    mapping(address => mapping(address => bool)) private hasVotedFor;
    mapping(address => Passenger) private passengersAddresses;
    mapping(bytes32 => Flight) private flights;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address firstAirlineAddress
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        registeredAirlines[firstAirlineAddress] = Airline(firstAirlineAddress, 0, new address[](0));
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

    modifier requireIsRegistered(address _airlineCaller){
        require(registeredAirlines[_airlineCaller].airlineAddress != 0, "Airline is not registered");
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
                // vote for it (if have not voted for it again)
                if(!hasVotedFor[_airlineCaller][_airlineAddress])
                {
                candidatesAirlines[_airlineAddress].voters.push(_airlineCaller);
                hasVotedFor[_airlineCaller][_airlineAddress] = true;
                }

                //and if the airline has enough votes
                if(candidatesAirlines[_airlineAddress].voters.length * 100 >= registeredAirlinesNum * 100 / 2)
                {
                    //register it
                    registeredAirlines[_airlineAddress] = candidatesAirlines[_airlineAddress];
                    delete(candidatesAirlines[_airlineAddress]);
                }
                    
            }else 
            {   // Add it as a candidate
              Airline memory airline = Airline(_airlineAddress, 0, new address[](1));
              airline.voters[0] = _airlineCaller;
              candidatesAirlines[_airlineAddress] = airline;
              hasVotedFor[_airlineCaller][_airlineAddress] = true;
            }
        }
       
    }
    function getAirlinesNumber()public view  returns(uint256){return registeredAirlinesNum;}

    /**
    * @dev Get the Airline details.
    *
    */
    function getAirlineStatus(address _airlineAddress)public view returns(uint256 funds, bool isRegistered)
    {
        funds = registeredAirlines[_airlineAddress].funds;
        isRegistered = registeredAirlines[_airlineAddress].airlineAddress != 0;
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
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    string flight,
                                    uint8 statusCode, 
                                    uint256 updatedTimestamp, 
                                    address airline
                                )
                                external
    {
        bytes32 key = getFlightKey(airline, flight, updatedTimestamp);
        flights[key] = Flight(flight, true, statusCode, updatedTimestamp, airline, new address[](0));
        flightKeys.push(key);
    }   

    function flightsAvailable() public view returns (bytes32[]) {
        return flightKeys;
    }


    /**
    * @dev Get the flight details.
    *
    */
    function getFlight
                        (
                            bytes32 key
                        )
                        public
                        view
                        returns(string flightName, uint statusCode, uint256 updatedTimestamp, address airline, address[] customersInsurances)
    {
        flightName = flights[key].flightName;
        statusCode = flights[key].statusCode;
        updatedTimestamp = flights[key].updatedTimestamp;
        airline = flights[key].airline;
        customersInsurances = flights[key].passengersInsurances;
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (  
                                bytes32 key, 
                                address passengerAddress                          
                            )
                            external
                            payable
    {
        require(msg.value <= 1 ether, "Insurrance cannot be more than 1 ether");
        passengersAddresses[passengerAddress] = Passenger(msg.value, 0);
        flights[key].passengersInsurances.push(passengerAddress);
    }

    /**
    * @dev Process the insurance for a flight
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string flight,
                                    uint256 updatedTimestamp,
                                    uint8 statusCode     
                                ) 
                                external 
                                requireIsOperational 
                                requireCallerIsAuthorized
                                {
        bytes32 key = getFlightKey(airline, flight, updatedTimestamp);
        flights[key].statusCode = statusCode;
        if (statusCode == 20) {
            for (uint i = 0; i < flights[key].passengersInsurances.length; i++) {
                creditInsurees(flights[key].passengersInsurances[i]);
            }
        }
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address _passengerAddress
                                )
                                internal
                                requireIsOperational
                                requireCallerIsAuthorized                         
    {
        
        uint256 deposit = passengersAddresses[_passengerAddress].deposit;
        passengersAddresses[_passengerAddress].deposit = passengersAddresses[_passengerAddress].deposit.sub(deposit);
        passengersAddresses[_passengerAddress].payout = passengersAddresses[_passengerAddress].payout.add(deposit).add(deposit / 2);
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address _passengerAddress
                            )
                            external
                            payable
                            requireIsOperational
                            requireCallerIsAuthorized
    {
        uint256 payout = passengersAddresses[_passengerAddress].payout;
        passengersAddresses[_passengerAddress].payout = passengersAddresses[_passengerAddress].payout.sub(payout);
        _passengerAddress.transfer(payout);
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
                            requireIsRegistered(_airlineAddress)
                            requireRegistrationFee                     
    {
        registeredAirlines[_airlineAddress].funds = registeredAirlines[_airlineAddress].funds.add(msg.value);
        registeredAirlinesNum = registeredAirlinesNum.add(1);
    }


    function getPassenger(address _address) public view returns (uint256, uint256){

        return (passengersAddresses[_address].deposit, passengersAddresses[_address].payout);
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

