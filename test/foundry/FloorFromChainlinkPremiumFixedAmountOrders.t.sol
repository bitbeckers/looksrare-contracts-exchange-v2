// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderStructs} from "../../contracts/libraries/OrderStructs.sol";
import {StrategyFloorFromChainlink} from "../../contracts/executionStrategies/StrategyFloorFromChainlink.sol";
import {FloorFromChainlinkPremiumOrdersTest} from "./FloorFromChainlinkPremiumOrders.t.sol";

contract FloorFromChainlinkPremiumFixedAmountOrdersTest is FloorFromChainlinkPremiumOrdersTest {
    function setUp() public override {
        _setPremium(0.1 ether);
        _setIsFixedAmount(1);
        _setSelectorTakerBid(StrategyFloorFromChainlink.executeFixedPremiumStrategyWithTakerBid.selector);
        super.setUp();
    }

    function testFloorFromChainlinkPremiumFixedAmountDesiredSalePriceGreaterThanMinPrice() public {
        (, , , , , , address implementation) = looksRareProtocol.strategyInfo(1);
        strategyFloorFromChainlink = StrategyFloorFromChainlink(implementation);

        // Floor price = 9.7 ETH, premium = 0.1 ETH, desired price = 9.8 ETH
        // Min price = 9.7 ETH
        (makerAsk, takerBid) = _createMakerAskAndTakerBid({premium: premium});
        _testFloorFromChainlinkPremiumFixedAmountDesiredSalePriceGreaterThanOrEqualToMinPrice(makerAsk, takerBid);
    }

    function testFloorFromChainlinkPremiumFixedAmountDesiredSalePriceEqualToMinPrice() public {
        (, , , , , , address implementation) = looksRareProtocol.strategyInfo(1);
        strategyFloorFromChainlink = StrategyFloorFromChainlink(implementation);

        // Floor price = 9.7 ETH, premium = 0.1 ETH, desired price = 9.8 ETH
        // Min price = 9.8 ETH
        (makerAsk, takerBid) = _createMakerAskAndTakerBid({premium: premium});
        makerAsk.minPrice = 9.8 ether;
        _testFloorFromChainlinkPremiumFixedAmountDesiredSalePriceGreaterThanOrEqualToMinPrice(makerAsk, takerBid);
    }

    function _testFloorFromChainlinkPremiumFixedAmountDesiredSalePriceGreaterThanOrEqualToMinPrice(
        OrderStructs.MakerAsk memory makerAsk,
        OrderStructs.TakerBid memory takerBid
    ) public {
        signature = _signMakerAsk(makerAsk, makerUserPK);

        _setPriceFeed();

        (bool isValid, bytes4 errorSelector) = strategyFloorFromChainlink.isMakerAskValid(makerAsk);
        assertTrue(isValid);
        assertEq(errorSelector, bytes4(0));

        _executeTakerBid(takerBid, makerAsk, signature);

        // Taker user has received the asset
        assertEq(mockERC721.ownerOf(1), takerUser);
        // Taker bid user pays the whole price
        assertEq(weth.balanceOf(takerUser), _initialWETHBalanceUser - 9.8 ether);
        // Maker ask user receives 98% of the whole price (2% protocol)
        assertEq(weth.balanceOf(makerUser), _initialWETHBalanceUser + 9.604 ether);
    }

    function testFloorFromChainlinkPremiumFixedAmountDesiredSalePriceLessThanMinPrice() public {
        (, , , , , , address implementation) = looksRareProtocol.strategyInfo(1);
        strategyFloorFromChainlink = StrategyFloorFromChainlink(implementation);

        // Floor price = 9.7 ETH, premium = 0.1 ETH, desired price = 9.8 ETH
        // Min price = 9.9 ETH
        (makerAsk, takerBid) = _createMakerAskAndTakerBid({premium: premium});

        makerAsk.minPrice = 9.9 ether;
        takerBid.maxPrice = makerAsk.minPrice;

        signature = _signMakerAsk(makerAsk, makerUserPK);

        _setPriceFeed();

        (bool isValid, bytes4 errorSelector) = strategyFloorFromChainlink.isMakerAskValid(makerAsk);
        assertTrue(isValid);
        assertEq(errorSelector, bytes4(0));

        _executeTakerBid(takerBid, makerAsk, signature);

        // Taker user has received the asset
        assertEq(mockERC721.ownerOf(1), takerUser);

        // Taker bid user pays the whole price
        assertEq(weth.balanceOf(takerUser), _initialWETHBalanceUser - 9.9 ether);
        // Maker ask user receives 98% of the whole price (2% protocol)
        assertEq(weth.balanceOf(makerUser), _initialWETHBalanceUser + 9.702 ether);
    }
}
