
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
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

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
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let secondAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(secondAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(secondAirline);

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can register an Airline using registerAirline() if it is funded', async () => {
    
    // ARRANGE
    let secondAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.fund({from: config.firstAirline, value: web3.utils.toWei("10", "ether")});
        await config.flightSuretyApp.registerAirline(secondAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(secondAirline);

    // ASSERT
    assert.equal(result, true, "Airline should be able to register another airline if it has provided funding");

  });


  it('(airline) after fifth airline can only add candidates airlines', async () => {
    // ARRANGE
    let secondAirline = accounts[2];
    let thirdAirline = accounts[3];
    let fourthAirline = accounts[4];
    let fifthAirline = accounts[5];
    let sixthAirline = accounts[6];
    
    await config.flightSuretyApp.fund({from: secondAirline, value: web3.utils.toWei("10", "ether")});
    
    await config.flightSuretyApp.registerAirline(thirdAirline, {from: config.firstAirline});
    await config.flightSuretyApp.fund({from: thirdAirline, value: web3.utils.toWei("10", "ether")});
    
    await config.flightSuretyApp.registerAirline(fourthAirline, {from: thirdAirline});
    await config.flightSuretyApp.fund({from: fourthAirline, value: web3.utils.toWei("10", "ether")});
    
    await config.flightSuretyApp.registerAirline(fifthAirline, {from: fourthAirline});
    await config.flightSuretyApp.fund({from: fifthAirline, value: web3.utils.toWei("10", "ether")});
    
    // ACT
    await config.flightSuretyApp.registerAirline(sixthAirline, {from: fifthAirline});
    
    // ASSERT
   let result5 = await config.flightSuretyData.isAirline.call(fifthAirline);
   let result6 = await config.flightSuretyData.isAirline.call(sixthAirline);
   let result6candidate = await config.flightSuretyData.isCandidate.call(sixthAirline);
   
   assert.equal(result5, true, "Fifth Airline can be registered");
   assert.equal(result6, false, "Sixth Airline should not be added as registered");
   assert.equal(result6candidate, true, "Sixth Airline should be added as a candidate");

    });
 

});
