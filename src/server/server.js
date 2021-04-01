import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';

let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
let oracles = [];
const returnedValues = [0, 10, 20, 30, 40, 50]

web3.eth.getAccounts()
	.then((accounts) => {
		web3.eth.defaultAccount = accounts[0];
		let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
		let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
		
		for (let i = 20; i <= 39; i++) {
			flightSuretyApp.methods.registerOracle().send({
				from: accounts[i],
				gas: 5000000,
				value: web3.utils.toWei("1", "ether")
			}, (err, response) => {
				flightSuretyApp.methods.getMyIndexes().call({from: accounts[i]}, (err, res) => {
					console.log(`Oracle registered ${accounts[i]}`)
					let oracle = [accounts[i]]
					oracle.push(res)
					oracles.push(oracle);
				})
			})
		}
		
		flightSuretyApp.events.OracleRequest({
			fromBlock: 0
		}, function (error, event) {
			if (error) console.log(error)
			let index = event.returnValues[0];
			let airline = event.returnValues[1];
			let flight = event.returnValues[2];
			let timestamp = event.returnValues[3];
			oracles.map(oracle => {
				if (oracle[1].indexOf(index) !== -1) {
					let randomInt = Math.floor(Math.random() * returnedValues.length)
					flightSuretyApp.methods
						.submitOracleResponse(index, airline, flight, timestamp, returnedValues[randomInt])
						.send({from: oracle[0], gas: 5000000}, (err, response) => {
							if (err) console.log(err)
							console.log(`Oracle ${oracle} responded with ${returnedValues[randomInt]} to ${flight} - ${airline} with ${timestamp}`)
							console.log('response ' + response)
						})
				}
			})
		});
		
		flightSuretyApp.events.OracleReport({
			fromBlock: 0
			}, function (error, event) {
				if (error) console.log(error)
				let airline = event.returnValues[0];
				let  flight = event.returnValues[1];
				let timestamp = event.returnValues[2];
				let statusCode = event.returnValues[3];
				console.log('Event from oracle report:airline ' + airline + ' flight ' + flight + ' timestamp ' + timestamp + ' statusCode ' + statusCode);
		});

		flightSuretyApp.events.FlightStatusInfo({
			fromBlock: 0
			}, function (error, event) {
				if (error) console.log(error)
				let airline = event.returnValues[0];
				let  flight = event.returnValues[1];
				let timestamp = event.returnValues[2];
				let statusCode = event.returnValues[3];
				console.log('Event from FlightStatusInfo: airline ' + airline + ' flight ' + flight + ' timestamp ' + timestamp + ' statusCode ' + statusCode);
		});
		

	})
	.catch(console.log)


const app = express();
app.get('/api', (req, res) => {
	res.send({
		message: 'An API for use with your Dapp!'
	})
})

export default app;