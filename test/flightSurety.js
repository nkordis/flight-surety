
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.owner});
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false, { from: config.owner});

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true, { from: config.owner});

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    const secondAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(secondAirline, { from: config.firstAirline});
    }
    catch(e) {

    }
    const result = await config.flightSuretyData.isAirline.call(secondAirline);

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can add funds if it is registered', async () => {
    // ARRANGE
    const secondAirline = accounts[2];

    // ACT
    await config.flightSuretyApp.fund({from: config.firstAirline, value: web3.utils.toWei("10", "ether")});

    let notRegisteredAddedFunds = true;
    try{
        await config.flightSuretyApp.fund({from: secondAirline, value: web3.utils.toWei("10", "ether")});
    }catch(e){
        notRegisteredAddedFunds = false;
    }


    // ASSERT
    const status = await config.flightSuretyData.getAirlineStatus.call(config.firstAirline);

    assert.equal(status[0], 10 * config.weiMultiple, "A registered airline should be able to add funds at least equal with the registration fee");
    assert.equal(notRegisteredAddedFunds, false, "A registered airline should not be able to add funds if it is not registered");

  });

  it('(airline) can register an Airline using registerAirline() if it is funded', async () => {
    
    // ARRANGE
    const secondAirline = accounts[2];

    // ACT
    await config.flightSuretyApp.registerAirline(secondAirline, { from:  config.firstAirline});
        
    // ASSERT
    const result = await config.flightSuretyData.isAirline.call(secondAirline);
    assert.equal(result, true, "Airline should be able to register another airline if it has provided funding");

  });


  it('(airline) after fifth airline can only add candidates airlines', async () => {
    // ARRANGE
    const secondAirline = accounts[2];
    const thirdAirline = accounts[3];
    const fourthAirline = accounts[4];
    const fifthAirline = accounts[5];
    const sixthAirline = accounts[6];
    
    await config.flightSuretyApp.fund({from: secondAirline, value: web3.utils.toWei("10", "ether")});
    
    await config.flightSuretyApp.registerAirline(thirdAirline, {from: secondAirline});
    await config.flightSuretyApp.fund({from: thirdAirline, value: web3.utils.toWei("10", "ether")});
    
    await config.flightSuretyApp.registerAirline(fourthAirline, {from: thirdAirline});
    await config.flightSuretyApp.fund({from: fourthAirline, value: web3.utils.toWei("10", "ether")});
    
    await config.flightSuretyApp.registerAirline(fifthAirline, {from: fourthAirline});
    await config.flightSuretyApp.fund({from: fifthAirline, value: web3.utils.toWei("10", "ether")});
    
    // ACT
    await config.flightSuretyApp.registerAirline(sixthAirline, {from: fifthAirline});
    
    // ASSERT
   const result5 = await config.flightSuretyData.isAirline.call(fifthAirline);
   const result6 = await config.flightSuretyData.isAirline.call(sixthAirline);
   const result6candidate = await config.flightSuretyData.isCandidate.call(sixthAirline);
   
   assert.equal(result5, true, "Fifth Airline can be registered");
   assert.equal(result6, false, "Sixth Airline should not be added as registered");
   assert.equal(result6candidate, true, "Sixth Airline should be added as a candidate");

    });

    it('(airline) Sixth airline should be registered if approved from half of the registered airlines', async () => {
        // ARRANGE
        const secondAirline = accounts[2];
        const thirdAirline = accounts[3];
        const sixthAirline = accounts[6];
        
        // ACT
        await config.flightSuretyApp.registerAirline(sixthAirline, {from: secondAirline});
        await config.flightSuretyApp.registerAirline(sixthAirline, {from: thirdAirline});
        
        // ASSERT
       const result6 = await config.flightSuretyData.isAirline.call(sixthAirline);
       const result6candidate = await config.flightSuretyData.isCandidate.call(sixthAirline);
       
       assert.equal(result6, true, "Sixth Airline should be added as registered");
       assert.equal(result6candidate, false, "Sixth Airline should had removed from candidates list");
    
    });
 
    it('(flight) can register a flight', async () => {
		// ARRANGE
		const flightName = 'FlightName';
		
		// ACT
		await config.flightSuretyApp.registerFlight(flightName, Date.now(), config.firstAirline, {from: config.firstAirline});

        const flightKeys = await config.flightSuretyData.flightsAvailable.call();
		const flightFetched = await config.flightSuretyData.getFlight.call(flightKeys[0]);
        
		// ASSERT
		assert.equal(flightFetched[0], flightName, "Flight name should be the same");
		
	})

    it('(passenger) can buy an insurance', async () => {
		// ARRANGE
		const passengerAddress = accounts[9];
		
		const flightKeys = await config.flightSuretyData.flightsAvailable.call();

		// ACT
		await config.flightSuretyApp.buy(flightKeys[0], {
			from: passengerAddress,
			value: web3.utils.toWei("0.5", "ether")
		});
		
		const flightFetched = await config.flightSuretyData.getFlight.call(flightKeys[0]);
		
        // ASSERT
		assert.equal(flightFetched[4][0], passengerAddress, "No registered customer with insurance for the flight");
	})

    /**
     * In order to test  "processFlightStatus" method in [FlightSuretyApp.sol] is set to public. (production status should be internal)
     */
 
    /*
    it('(multiparty) can payout passengers', async () => {

        //ARRANGE
        const flightName = 'FlightName';
        const date = Date.now();
        const passengerAddress = accounts[9];

        await config.flightSuretyApp.registerFlight(flightName, date, config.firstAirline, {from: config.firstAirline});
        const flightKeys = await config.flightSuretyData.flightsAvailable.call();
        await config.flightSuretyApp.buy(flightKeys[1], {
			from: passengerAddress,
			value: web3.utils.toWei("0.5", "ether")
		});


        //ACT
        await config.flightSuretyApp.processFlightStatus(config.firstAirline, flightName, date, 20); 
        const newPassengerPayoutAmount = await config.flightSuretyData.getPassenger(passengerAddress);

        //ASSERT
        assert.equal("750000000000000000", newPassengerPayoutAmount[1], "Passengers new payout amount should be half of the deposit");

    })
    */
});
