// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IConnextHandler} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnextHandler.sol";
import {CallParams, XCallArgs} from "@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XTransfer { 
  // ConnextHandler contract on origin domain
  IConnextHandler public connext = IConnextHandler(0xB4C1340434920d70aD774309C75f9a4B679d801e); 

  // TEST ERC20 token on origin domain
  ERC20 public token = ERC20(0x7ea6eA49B0b0Ae9c5db7907d139D9Cd3439862a1); 

  // Function that the user will call
  function transfer(address recipient, uint256 amount) external {
    require(
      token.allowance(msg.sender, address(this)) >= amount,
      "User must approve amount to this contract"
    );
    
    // User's funds are transferred to this contract
    token.transferFrom(msg.sender, address(this), amount);

    // This contract approves spend to the Connext contract
    token.approve(address(connext), amount);

    CallParams memory callParams = CallParams({
      to: recipient, // wallet receiving the funds on the destination
      callData: "", // empty here because we're only sending funds
      originDomain: 1735353714, // from Goerli
      destinationDomain: 1735356532, // to Optimism-Goerli
      agent: msg.sender, // address allowed to execute transaction on destination side in addition to relayers
      recovery: msg.sender, // fallback address to send funds to if execution fails on destination side
      forceSlow: false, // option to force slow path instead of paying 0.05% fee on fast path transfers
      receiveLocal: false, // option to receive the local bridge-flavored asset instead of the adopted asset
      callback: address(0), // zero address because we're not using a callback
      callbackFee: 0, // fee paid to relayers; relayers don't take any fees on testnet
      relayerFee: 0, // fee paid to relayers; relayers don't take any fees on testnet
      destinationMinOut: (amount / 100) * 99 // minimum amount acceptable due to slippage from the AMM (1% here)
    });

    XCallArgs memory xcallArgs = XCallArgs({
      params: callParams,
      transactingAsset: address(token), // the token being transferred to the target contract
      transactingAmount: amount, // amount of ERC20 to transfer
      originMinOut: (amount / 100) * 99 // minimum amount acceptable due to slippage from the AMM (1% here)
    });

    connext.xcall(xcallArgs);
  }
}