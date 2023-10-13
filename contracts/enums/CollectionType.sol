// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice CollectionType is used in OrderStructs.Maker's collectionType to determine the collection type being traded.
 */
//TODO explore if we need to add a Hypercerts type even though it is an ERC1155
enum CollectionType {
    ERC721,
    ERC1155
}
