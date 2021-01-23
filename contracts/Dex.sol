pragma solidity 0.6.3;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract Dex {

    using SafeMath for uint;
       
    enum Side {
        BUY,
        SELL
    }
    
    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }
    
    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint filled;
        uint price;
        uint date;
    }
    
    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;
    address public admin;
    uint public nextOrderId;
    uint public nextTradeId;
    bytes32 constant DAI = bytes32('DAI');
    
    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );
    
    modifier tokenIsNotDai(bytes32 ticker) {
       require(ticker != DAI, 'cannot trade DAI');
       _;
    }     
    
    modifier tokenExist(bytes32 ticker) {
        require(
            tokens[ticker].tokenAddress != address(0),
            'this token does not exist'
        );
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    /**
    * @dev Return List in order book filter by ticker and side
    * @param ticker token type
    * @param side  BUY or SELL
    * @return list of order book filter by ticker and side
    */
    function getOrders(
      bytes32 ticker, 
      Side side) 
      external 
      view
      returns(Order[] memory) {
      return orderBook[ticker][uint(side)];
    }

    /**
    * @dev Return Token List
    * @return a token list
    */
    function getTokens() 
      external 
      view 
      returns(Token[] memory) {
      Token[] memory _tokens = new Token[](tokenList.length);
      for (uint i = 0; i < tokenList.length; i++) {
        _tokens[i] = Token(
          tokens[tokenList[i]].ticker,
          tokens[tokenList[i]].tokenAddress
        );
      }
      return _tokens;
    }
    
    /**
    * @dev To initialize tokens use in this DEX
    * @param ticker token
    * @param tokenAddress  address for the token
    */
    function addToken(
        bytes32 ticker,
        address tokenAddress)
        onlyAdmin()
        external {
        tokens[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }
    
    /**
    * @dev Allow trader to deposit amount from their wallet to their trader balance
    * @param ticker token type to be deposited
    * @param amount  amount
    */
    function deposit(
        uint amount,
        bytes32 ticker)
        tokenExist(ticker)
        external {
        IERC20(tokens[ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
    }
    
    /**
    * @dev Withdraw amount from trader balance to trader's wallet
    * @param ticker token type
    * @param amount  amount in trader balance account
    */
    function withdraw(
        uint amount,
        bytes32 ticker)
        tokenExist(ticker)
        external {
        require(
            traderBalances[msg.sender][ticker] >= amount,
            'balance too low'
        ); 
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount);
        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
    }
    
    /**
    * @dev Create limit order either BUY or SELL
    * @param ticker token type
    * @param amount amount want to trade
    * @param price price limit to perform the trade
    * @param side type of trade, BUY or SELL
    */
    function createLimitOrder(
        bytes32 ticker,
        uint amount,
        uint price,
        Side side)
        tokenExist(ticker)
        tokenIsNotDai(ticker)
        external {
        if(side == Side.SELL) {
        // make sure trader has enough token to sell
            require(
                traderBalances[msg.sender][ticker] >= amount, 
                'token balance too low'
            );
        } else {
            // make sure trader has enough dai to buy
            require(
                traderBalances[msg.sender][DAI] >= amount.mul(price),
                'dai balance too low'
            );
        }
        // create new limit order
        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(Order(
            nextOrderId,
            msg.sender,
            side,
            ticker,
            amount,
            0,
            price,
            now 
        ));
        // check if order book has already transcation 
        // if yes, get the orderbook length, no then get 0 as it is a new order book
        uint i = orders.length > 0 ? orders.length - 1 : 0;
        while(i > 0) {
            // if it's a buy order, then allocate price in descending order, maximum price should be at front
            if(side == Side.BUY && orders[i - 1].price > orders[i].price) {
                break;   
            }
            // if it's a sell order, then allocate price in acending order, minmum price should be at front
            if(side == Side.SELL && orders[i - 1].price < orders[i].price) {
                break;   
            }
            Order memory order = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = order;
            i--;
        }
        nextOrderId++;
    }
    
    /**
    * @dev Create market order either BUY or SELL
    * @param ticker token type
    * @param amount amount want to trade
    * @param side type of trade, BUY or SELL
    */
    function createMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side)
        tokenExist(ticker)
        tokenIsNotDai(ticker)
        external {
        if(side == Side.SELL) {
            // make sure trader has enough token to sell
            require(
                traderBalances[msg.sender][ticker] >= amount, 
                'token balance too low'
            );
        }
        // retrieve either buy or sell record from order book base on parameter side
        Order[] storage orders = orderBook[ticker][uint(side == Side.BUY ? Side.SELL : Side.BUY)];
        uint i;
        uint remaining = amount;
        
        while(i < orders.length && remaining > 0) {
            // check each order book transaction , how many available amount is still available to trade
            uint available = orders[i].amount.sub(orders[i].filled);
            // check if the remaining amount of the market trade order can match the available amount
            uint matched = (remaining > available) ? available : remaining;
            // update the remaining amount
            remaining = remaining.sub(matched);
            // update the matched order's filled field
            orders[i].filled = orders[i].filled.add(matched);
            // announce a new trade order is performed
            emit NewTrade(
                nextTradeId,
                orders[i].id,
                ticker,
                orders[i].trader,
                msg.sender,
                matched,
                orders[i].price,
                now
            );
            // update trader balance for both limit order trader and market order trader
            // For seller, market trader will get DAI and take out ticker amount from their balance
            //             limit order trade will get the ticker amount and pay with DAI    
            if(side == Side.SELL) {
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(matched);
                traderBalances[msg.sender][DAI] = traderBalances[msg.sender][DAI].add(matched.mul(orders[i].price));
                traderBalances[orders[i].trader][ticker] = traderBalances[orders[i].trader][ticker].add(matched);
                traderBalances[orders[i].trader][DAI] = traderBalances[orders[i].trader][DAI].sub(matched.mul(orders[i].price));
            }
            // For buyer, market order trader will get token amount and pay DAI for this trade
            //            limit order trader will get DAI and release the token amount
            if(side == Side.BUY) {
                require(
                    traderBalances[msg.sender][DAI] >= matched.mul(orders[i].price),
                    'dai balance too low'
                );
                traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(matched);
                traderBalances[msg.sender][DAI] = traderBalances[msg.sender][DAI].sub(matched.mul(orders[i].price));
                traderBalances[orders[i].trader][ticker] = traderBalances[orders[i].trader][ticker].sub(matched);
                traderBalances[orders[i].trader][DAI] = traderBalances[orders[i].trader][DAI].add(matched.mul(orders[i].price));
            }
            // update the order book by deleting the completed transaction 
            nextTradeId++;
            i++;
        }
        
        i = 0;
        while(i < orders.length && orders[i].filled == orders[i].amount) {
            for(uint j = i; j < orders.length - 1; j++ ) {
                orders[j] = orders[j + 1];
            }
            orders.pop();
            i++;
        }
    }

}