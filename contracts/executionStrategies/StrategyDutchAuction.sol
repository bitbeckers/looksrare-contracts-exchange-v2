// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {StrategyBase} from "./StrategyBase.sol";
import {IExecutionStrategy} from "../interfaces/IExecutionStrategy.sol";
import {OrderStructs} from "../libraries/OrderStructs.sol";

/**
 * @title StrategyDutchAuction
 * @author LooksRare protocol team (👀,💎)
 */
contract StrategyDutchAuction is StrategyBase {
    // Address of the protocol
    address public immutable LOOKSRARE_PROTOCOL;

    /**
     * @notice Constructor
     * @param _looksRareProtocol Address of the LooksRare protocol
     */
    constructor(address _looksRareProtocol) {
        LOOKSRARE_PROTOCOL = _looksRareProtocol;
    }

    /**
     * @inheritdoc IExecutionStrategy
     * @notice The execution price decreases linearly within the defined period
     * @dev The client has to provide the Dutch auction's start price as the additionalParameters
     */
    function executeStrategyWithTakerBid(
        OrderStructs.TakerBid calldata takerBid,
        OrderStructs.MakerAsk calldata makerAsk
    )
        external
        view
        override
        returns (
            uint256 price,
            uint256[] memory itemIds,
            uint256[] memory amounts,
            bool isNonceInvalidated
        )
    {
        if (msg.sender != LOOKSRARE_PROTOCOL) revert WrongCaller();

        uint256 itemIdsLength = makerAsk.itemIds.length;

        if (itemIdsLength == 0 || itemIdsLength != makerAsk.amounts.length) revert OrderInvalid();
        for (uint256 i; i < itemIdsLength; ) {
            uint256 amount = makerAsk.amounts[i];
            if (amount == 0) revert OrderInvalid();
            if (makerAsk.itemIds[i] != takerBid.itemIds[i] || amount != takerBid.amounts[i]) revert OrderInvalid();

            unchecked {
                ++i;
            }
        }

        uint256 startPrice = abi.decode(makerAsk.additionalParameters, (uint256));

        if (startPrice < makerAsk.minPrice) revert OrderInvalid();

        uint256 duration = makerAsk.endTime - makerAsk.startTime;
        uint256 decayPerSecond = (startPrice - makerAsk.minPrice) / duration;

        uint256 elapsedTime = block.timestamp - makerAsk.startTime;
        price = startPrice - elapsedTime * decayPerSecond;

        if (takerBid.maxPrice < price) revert BidTooLow();

        isNonceInvalidated = true;

        itemIds = makerAsk.itemIds;
        amounts = makerAsk.amounts;
    }

    /**
     * @inheritdoc IExecutionStrategy
     */
    function executeStrategyWithTakerAsk(OrderStructs.TakerAsk calldata, OrderStructs.MakerBid calldata)
        external
        pure
        override
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory,
            bool
        )
    {
        revert OrderInvalid();
    }
}
