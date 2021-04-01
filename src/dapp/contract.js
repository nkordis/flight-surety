import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];
			
			this.flightSuretyData.methods.authorizeCaller(this.flightSuretyApp.options.address).send({from: this.owner, gas: 5000000});
			
			this.airlines.push(accts[1])
			
			callback();

        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlights(callback) {
		let self = this;
		self.flightSuretyData.methods
            .flightsAvailable()
            .call({ from: self.owner}, callback);
	}

    registerFlight(flightNumber, flightDate, flightAirline, callback) {
		let self = this;
		self.flightSuretyApp.methods
            .registerFlight(flightNumber, flightDate, flightAirline)
			.send({from: flightAirline, gas: 5000000}, callback); 
	}
	
	fetchFlight(key, callback) {
		let self = this;
		
		self.flightSuretyData.methods.getFlight(key).call((err, result) => {
			callback(err, result);
		})
	}

    getPassenger(passengerAddress, callback) {
		let self = this;
		self.flightSuretyData.methods.getPassenger(passengerAddress).call(//{from: passengerAddress},
			(err, res) => {
				callback(err, res);
			})
	}

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    buy(flightKey, amount, passenger, callback) {
		let self = this;
		self.flightSuretyApp.methods.buy(flightKey).send({
			from: passenger,
			gas: 6721975,
			value: this.web3.utils.toWei(amount, "ether")
		}, (error, result) => {
			callback(error, result)
		})
	}
	
	pay(passengerAddress, callback) {
		let self = this;
		self.flightSuretyApp.methods.pay().send({
			from: passengerAddress,
			gas: 6721975
		}, (err, res) => {
			callback(err, res);
		})
	}

    

}