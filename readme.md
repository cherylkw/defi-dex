# Decentralized Exchange (DEX - orderbook) Dapp

## About this exercise

A decentralized exchange allow trading with ERC20 tokens using orderbook. The quote currency is DAI. There are 2 trading options : limited order and market order. Users can create buy/sell limit/market orders. They can deposit/ withdraw tokens between their Metamask wallets and their DEX account.

## Archiect of DEX

User wallet (default to be Metamask)
Frontend (Web app)
Smart contract (Blockchain)

A frontend which is the Web app is connected to both user wallet and the smart contract. User uses the web app to interact with the DEX smart contract. When sending any transaction, user wallet will prompt the user for confirmation.

## Preset data for interaction 

# Mock tokens

Mock 4 ERC20 tokens (Bat, Dai, Rep, Zrx) for this project instead of interact with live tokens

# Preset order and trade data

Preset trade data and order data when deploy the contract in "2_deploy_contracts.js"

## Youtube Demo

https://youtu.be/8XcMc3k0Gt0

## Pre-requisites and programs used versions:

- Truffle v5.1.7 (core: 5.1.7)
- Solidity v0.6.3 (solc-js)
- Node v10.17.0
- Web3.js v1.2.1
- npm 6.11.3
- Ganache CLI v6.7.0 (ganache-core: 2.8.0)
- MetaMask V7.7.3
- Openzeppelin

## Setting up the development environment

1. Install Truffle: 
    >npm install -g truffle

2. Install ganache-cli:
    >npm install -g ganache-cli

3. Install MetaMask in your browser (https://metamask.io/)

4. Install Openzepplin testing package*
    >npm install @openzeppelin/text-helpers

5. Install react moment for displaying date and time in human readable format under "/client":
    >npm install moment react-moment

6. Install recharts for displaying trade price in chart format under "/client":
    >npm install recharts

* Note: (4) Truffle has already an integrated debugger, so it is optional to install external testing API.

## Installation/Running

**Launching local blockchain with Ganache**

First launch the local testing blockchain with 10 default testing accounts which contains ETH.
Open up a new seperate terminal, and run the following command:

    >truffle develop

New blockchain listens on **127.0.0.1:9545** by default
Copy the MNEMONIC seed to Metamask and connect Metamask as "LocalHost 9545" on the port listed above.

**In order to keep development environment running, do not close this terminal**

**Clone the project**

Open up another new terminal, make sure the ganache-cli terminal is running at the same time.

1. git clone <url of this project>

2. Move to the directory
    >npm install

3. Move to "client" directory
    >npm install web3

4. Compile the contracts
    >truffle compile

5.  Migrate to ganache-cli
    >truffle migrate --reset

6. Run tests. (All tests should pass)
    >truffle test

7. Run Dapp, move to client folder
    >npm start

## Visiting an URL and interact with the application

- http://localhost:3000/
- This Dapp requires to interact with MetaMask. When the dapp loaded, MetaMask pop-up will appear if installed properly, requesting your approveal to allow DEX Dapp connect to MetaMask wallet. Please choose **Connect**.

## Project developed by : Solidity, Smart contract, Web3, React, bootstrap