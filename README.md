# STXCompounder

## Overview

`STXCompounder` is a Clarity smart contract designed for staking Stacks (STX) and earning compounded rewards. Users can deposit STX into the contract and in return receive `ststx`, a fungible token representing their share of the staked STX and any accumulated rewards. This `ststx` token provides liquidity for staked assets.

The contract includes mechanisms for reward distribution (intended to be triggered by an authorized `rewards-distributor` contract) and administrative controls for pausing contract operations and emergency withdrawals.

## Features

- **STX Staking:** Deposit STX to participate in the compounding mechanism.
- **Liquid Staking Token (`ststx`):** Receive `ststx` tokens equivalent to your STX deposit, representing your staked position.
- **Unstaking:** Burn `ststx` tokens to withdraw your underlying STX.
- **Reward Compounding:** Rewards are compounded by minting new `ststx` tokens to the contract, increasing the value backing each `ststx` token over time.
- **Admin Controls:**
  - Pause/unpause critical contract functions.
  - Perform an emergency withdrawal of all STX in the contract.
  - Set an authorized `rewards-distributor` contract.

## Core Components

### Fungible Token

- **`ststx`**: A fungible token minted to users upon staking STX and burned upon unstaking. It represents a share of the total STX held by the contract, including compounded rewards.

### Key Data Variables

- **`deposits` (map):** Stores the amount of STX deposited by each user.
  - Key: `{ user: principal }`
  - Value: `{ amount: uint }`
- **`total-deposited` (uint):** Tracks the total amount of STX currently deposited in the contract.
- **`contract-paused` (bool):** A flag to pause or unpause certain contract functions. Default: `false`.
- **`admin` (principal):** The address of the contract administrator. Default: `tx-sender` (deployer).
- **`rewards-distributor` (optional principal):** The address of an external contract authorized to call `compound-rewards`. Default: `none`.

### Constants (Error Codes)

- **`ERR-NOT-AUTHORIZED (err u100)`:** Returned when an action is attempted by an unauthorized principal.
- **`ERR-INSUFFICIENT-BALANCE (err u101)`:** Returned when a user attempts to unstake more STX than their deposit allows or burn more `ststx` than they own.
- **`ERR-INVALID-AMOUNT (err u102)`:** Returned when an invalid amount (e.g., zero) is provided to a function.

## Public Functions

These functions can be called by users to interact with the contract.

### `stake (amount uint)`

Allows users to deposit STX into the contract and receive an equivalent amount of `ststx` tokens.

- **Pre-conditions:**
  - Contract must not be paused.
- **Actions:**
  - Transfers `amount` STX from `tx-sender` to the contract.
  - Updates the user's deposit in the `deposits` map.
  - Increments `total-deposited`.
  - Mints `amount` of `ststx` to `tx-sender`.
- **Returns:** `(ok true)` on success.

### `unstake (amount uint)`

Allows users to burn `ststx` tokens and withdraw a corresponding amount of STX.

- **Pre-conditions:**
  - User must have sufficient `ststx` to burn (implicitly, sufficient deposited STX).
  - Contract must not be paused.
- **Actions:**
  - Burns `amount` of `ststx` from `tx-sender`.
  - Transfers `amount` STX from the contract to `tx-sender`.
  - Updates the user's deposit in the `deposits` map.
  - Decrements `total-deposited`.
- **Returns:** `(ok true)` on success.

### `compound-rewards (reward uint)`

Allows the authorized `rewards-distributor` to add rewards to the system by minting `ststx` to the contract itself. This increases the total supply of `ststx` relative to the directly deposited STX, effectively distributing rewards to all `ststx` holders.

- **Pre-conditions:**
  - `reward` amount must be greater than zero.
  - `rewards-distributor` must be set.
  - Caller (`tx-sender`) must be the `rewards-distributor`.
- **Actions:**
  - Mints `reward` amount of `ststx` to the contract's address (`as-contract tx-sender`).
- **Returns:** `(ok true)` on success.

### `set-rewards-distributor (distributor principal)`

Allows the `admin` to set or update the address of the `rewards-distributor` contract.

- **Pre-conditions:**
  - Caller (`tx-sender`) must be the `admin`.
- **Actions:**
  - Sets the `rewards-distributor` variable.
- **Returns:** `(ok true)` on success.

## Read-Only Functions

These functions allow anyone to view contract state without making any changes.

### `get-deposit (user principal)`

- **Returns:** The amount of STX deposited by the specified `user`. Defaults to `u0` if no deposit exists.

### `get-total-deposited`

- **Returns:** The total amount of STX currently deposited in the contract.

### `get-token-balance (user principal)`

- **Returns:** The `ststx` token balance of the specified `user`.

## Admin Functions

These functions can only be called by the `admin`.

### `toggle-pause`

Allows the `admin` to pause or unpause critical contract functions (`stake`, `unstake`).

- **Pre-conditions:**
  - Caller (`tx-sender`) must be the `admin`.
- **Actions:**
  - Toggles the `contract-paused` boolean variable.
- **Returns:** `(ok true)` on success.

### `emergency-withdraw`

Allows the `admin` to withdraw all STX held by the contract to their own address. This is intended for emergency situations.

- **Pre-conditions:**
  - Contract must be paused.
  - Caller (`tx-sender`) must be the `admin`.
- **Actions:**
  - Transfers the entire STX balance of the contract to the `admin`.
- **Returns:** `(ok balance)` where `balance` is the amount of STX withdrawn.

## Integration Points

- **`STXRewardsDistributor.clar`:** This contract is intended to be set as the `rewards-distributor` and will call `compound-rewards` to distribute staking rewards.
- **`Governance.clar`:** The `Governance` contract uses `(contract-call? .STXCompounder get-deposit tx-sender)` to determine a user's voting power based on their STX deposit in `STXCompounder`.
