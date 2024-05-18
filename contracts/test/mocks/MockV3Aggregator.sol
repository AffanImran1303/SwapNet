// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {FeedRegistryInterface} from "@chainlink/brownie/interfaces/FeedRegistryInterface.sol";

contract MockV3Aggregator {
    uint256 public constant version = 0;

    uint8 public decimal;
    int256 public latestAnswer;
    uint256 public latestTimestamp;
    uint256 public latestRound;

    mapping(uint256 => int256) public getAnswer;
    mapping(uint256 => uint256) public getTimestamp;
    mapping(uint256 => uint256) private getStartedAt;

    mapping(address baseToken => mapping(address quoteToken => int256 price)) getAnswerForTokenPair;
    mapping(address baseToken => mapping(address quoteToken => uint8 decimal)) getDecimalsForTokenPair;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimal = _decimals;
        updateAnswer(_initialAnswer);
    }

    function decimals(address _baseToken, address _quoteToken) public view returns (uint256) {
        return getDecimalsForTokenPair[_baseToken][_quoteToken];
    }

    function updateAnswerForTokenPair(address _baseToken, address _quoteToken, int256 _answer, uint8 _decimals)
        public
    {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        getAnswerForTokenPair[_baseToken][_quoteToken] = _answer;
        getDecimalsForTokenPair[_baseToken][_quoteToken] = _decimals;
    }

    function updateAnswer(int256 _answer) public {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = block.timestamp;
        getStartedAt[latestRound] = block.timestamp;
    }

    function updateRoundData(uint80 _roundId, int256 _answer, uint256 _timestamp, uint256 _startedAt) public {
        latestRound = _roundId;
        latestAnswer = _answer;
        latestTimestamp = _timestamp;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = _timestamp;
        getStartedAt[latestRound] = _startedAt;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, getAnswer[_roundId], getStartedAt[_roundId], getTimestamp[_roundId], _roundId);
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            uint80(latestRound),
            getAnswer[latestRound],
            getStartedAt[latestRound],
            getTimestamp[latestRound],
            uint80(latestRound)
        );
    }

    function latestRoundData(address _base, address _quote)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (uint80(1), getAnswerForTokenPair[_base][_quote], block.timestamp, block.timestamp, uint80(1));
    }

    function description() external pure returns (string memory) {
        return "v0.6/tests/MockV3Aggregator.sol";
    }
}
