// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/IOwnable.sol

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFMigratableConsumerV2Plus.sol

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  event CoordinatorSet(address vrfCoordinator);

  /// @notice Sets the VRF Coordinator address
  /// @notice This method should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
}

// lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFSubscriptionV2Plus.sol

/// @notice The IVRFSubscriptionV2Plus interface defines the subscription
/// @notice related methods implemented by the V2Plus coordinator.
interface IVRFSubscriptionV2Plus {
  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint256 subId, address to) external;

  /**
   * @notice Accept subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner) external;

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription with LINK, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   * @dev Note to fund the subscription with Native, use fundSubscriptionWithNative. Be sure
   * @dev  to send Native with the call, for example:
   * @dev COORDINATOR.fundSubscriptionWithNative{value: amount}(subId);
   */
  function createSubscription() external returns (uint256 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return nativeBalance - native balance of the subscription in wei.
   * @return reqCount - Requests count of subscription.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint256 subId
  )
    external
    view
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address owner, address[] memory consumers);

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint256 subId) external view returns (bool);

  /**
   * @notice Paginate through all active VRF subscriptions.
   * @param startIndex index of the subscription to start from
   * @param maxCount maximum number of subscriptions to return, 0 to return all
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * @dev should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveSubscriptionIds(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  /**
   * @notice Fund a subscription with native.
   * @param subId - ID of the subscription
   * @notice This method expects msg.value to be greater than or equal to 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol

// End consumer library.
library VRFV2PlusClient {
  // extraArgs will evolve to support new features
  bytes4 public constant EXTRA_ARGS_V1_TAG = bytes4(keccak256("VRF ExtraArgsV1"));
  struct ExtraArgsV1 {
    bool nativePayment;
  }

  struct RandomWordsRequest {
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;
  }

  function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/access/ConfirmedOwnerWithProposal.sol

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line gas-custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line gas-custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC721/IERC721.sol)

/**
 * @dev Required interface of an ERC-721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC-721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC-721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// lib/openzeppelin-contracts/contracts/utils/Pausable.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/access/ConfirmedOwner.sol

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol

// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fields for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - abi-encoded extra args
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}

// lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinatorV2Plus.
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBaseV2Plus, and can
 * @dev initialize VRFConsumerBaseV2Plus's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumerV2Plus is VRFConsumerBaseV2Plus {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _subOwner)
 * @dev       VRFConsumerBaseV2Plus(_vrfCoordinator, _subOwner) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create a subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords, extraArgs),
 * @dev see (IVRFCoordinatorV2Plus for a description of the arguments).
 *
 * @dev Once the VRFCoordinatorV2Plus has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBaseV2Plus.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @inheritdoc IVRFMigratableConsumerV2Plus
   */
  function setCoordinator(address _vrfCoordinator) external override onlyOwnerOrCoordinator {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);

    emit CoordinatorSet(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}

// src/Raffle.sol

/**
 * @title Raffle
 * @dev A contract for creating NFT raffles with secure random winner selection using Chainlink VRF
 */
contract Raffle is VRFConsumerBaseV2Plus, ReentrancyGuard, Pausable {
    // Custom errors
    error Raffle__RaffleNotActive();
    error Raffle__RaffleHasEnded();
    error Raffle__NotEnoughTickets();
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleStillActive();
    error Raffle__NoTicketsPurchased();
    error Raffle__TicketCountMustBeMoreThanZero();
    error Raffle__TicketPriceMustBeMoreThanZero();
    error Raffle__NFTTransferFailed();
    error Raffle__RefundFailed();
    error Raffle__PayoutFailed();
    error Raffle__FeeSendFailed();
    error Raffle__RaffleDoesNotExist();
    error Raffle__RequestAlreadyExists();
    error Raffle__RequestNotFound();
    error Raffle__WinnerAlreadySelected();
    error Raffle__RequestNotFulfilled();
    error Raffle__InvalidRaffleDuration();
    error Raffle__MinTicketsExceedTotalTickets();
    error Raffle__TooManyTicketsInOneTransaction();
    error Raffle__RaffleNotInOpenState();
    error Raffle__RaffleNotPendingWinner();
    error Raffle__RaffleCannotBeCancelled();
    error Raffle__NoTicketsToRefund();

    // Raffle states
    enum RaffleState {
        OPEN,
        PENDING_WINNER,
        COMPLETED,
        CANCELED
    }

    struct RaffleInfo {
        address nftAddress;
        uint256 tokenId;
        address owner;
        uint256 ticketCount;
        uint256 ticketPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 totalTicketsSold;
        uint256 totalPrize;
        uint256 numberOfTicketsToBeSoldForRaffleToExecute;
        RaffleState state;
        address winner;
        uint256 requestId;
    }

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    // Constants
    uint256 private constant PLATFORM_FEE_PERCENTAGE = 10;
    uint256 private constant MAX_TICKET_PURCHASES_PER_BATCH = 100;
    uint256 public constant MIN_RAFFLE_DURATION = 1 hours;
    uint256 public constant MAX_RAFFLE_DURATION = 30 days;

    // State variables
    uint256 public raffleCounter;
    address public immutable contractOwner;
    address private immutable i_platformWallet;
    uint256 public immutable s_subscriptionId;
    bytes32 private immutable s_keyHash;
    
    // Enhanced gas parameters
    uint32 public callbackGasLimit = 300000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    // Mappings
    mapping(uint256 => RaffleInfo) public raffles;
    mapping(uint256 => RequestStatus) public s_requests;
    mapping(uint256 => uint256) private s_requestIdToRaffleId;
    // Store ticket holders more efficiently
    mapping(uint256 => mapping(uint256 => address)) private raffleTickets;
    // Track ticket purchases per user to enable refunds
    mapping(uint256 => mapping(address => uint256)) public userTicketCounts;
    // Mapping to track raffle participants for more efficient refunds
    mapping(uint256 => address[]) public raffleParticipants;

    // Events
    event TicketPurchased(uint256 indexed raffleId, address indexed buyer, uint256 numberOfTickets, uint256 totalPaid);
    event RaffleCreated(
        uint256 indexed raffleId, 
        address indexed owner, 
        address indexed nftAddress, 
        uint256 tokenId, 
        uint256 ticketCount, 
        uint256 endTime, 
        uint256 minTickets, 
        uint256 ticketPrice
    );
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prize);
    event RandomWordsRequested(uint256 indexed raffleId, uint256 indexed requestId);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RaffleCancelled(uint256 indexed raffleId, string reason);
    event TicketsRefunded(uint256 indexed raffleId, address indexed participant, uint256 amount);
    event NFTReturned(uint256 indexed raffleId, address indexed owner, address indexed nftAddress, uint256 tokenId);
    event CallbackGasLimitUpdated(uint32 oldLimit, uint32 newLimit);
    event PlatformFeeReceived(uint256 indexed raffleId, uint256 amount);

    /**
     * @dev Constructor initializes the contract with Chainlink VRF parameters and platform settings
     * @param subscriptionId Chainlink VRF subscription ID
     * @param keyHash Chainlink VRF key hash
     * @param platformWallet Address to receive platform fees
     * @param vrfCoordinator Address of the VRF coordinator
     */
    constructor(
        uint256 subscriptionId,
        bytes32 keyHash,
        address platformWallet,
        address vrfCoordinator
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        i_platformWallet = platformWallet;
        contractOwner = msg.sender;
    }
    
    /**
     * @dev Modifier that restricts access to the contract owner
     */
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Caller is not the contract owner");
        _;
    }

    /**
     * @dev Creates a new raffle
     * @param nftAddress Address of the NFT contract
     * @param tokenId Token ID of the NFT
     * @param ticketCount Total number of tickets available
     * @param ticketPrice Price per ticket in wei
     * @param raffleLengthInSeconds Duration of the raffle
     * @param minTicketsRequired Minimum number of tickets that must be sold for raffle to be valid
     */
    function createRaffle(
        address nftAddress,
        uint256 tokenId,
        uint256 ticketCount,
        uint256 ticketPrice,
        uint256 raffleLengthInSeconds,
        uint256 minTicketsRequired
    ) external whenNotPaused {
        if (ticketCount == 0) revert Raffle__TicketCountMustBeMoreThanZero();
        if (ticketPrice == 0) revert Raffle__TicketPriceMustBeMoreThanZero();
        if (raffleLengthInSeconds < MIN_RAFFLE_DURATION || raffleLengthInSeconds > MAX_RAFFLE_DURATION) 
            revert Raffle__InvalidRaffleDuration();
        if (minTicketsRequired > ticketCount) revert Raffle__MinTicketsExceedTotalTickets();

        // Transfer NFT to contract safely
        _transferNFTToContract(nftAddress, tokenId);

        // Create the raffle
        _createRaffleInternal(
            nftAddress,
            tokenId,
            ticketCount,
            ticketPrice,
            raffleLengthInSeconds,
            minTicketsRequired
        );
    }
    
    /**
     * @dev Helper function to transfer NFT to contract
     */
    function _transferNFTToContract(address nftAddress, uint256 tokenId) private {
        try IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId) {
            // Transfer successful
        } catch {
            revert Raffle__NFTTransferFailed();
        }
    }
    
    /**
     * @dev Helper function to create a raffle
     */
    function _createRaffleInternal(
        address nftAddress,
        uint256 tokenId,
        uint256 ticketCount,
        uint256 ticketPrice,
        uint256 raffleLengthInSeconds,
        uint256 minTicketsRequired
    ) private {
        uint256 raffleId = raffleCounter;
        uint256 endTime = block.timestamp + raffleLengthInSeconds;
        
        raffles[raffleId] = RaffleInfo({
            nftAddress: nftAddress,
            tokenId: tokenId,
            owner: msg.sender,
            ticketCount: ticketCount,
            ticketPrice: ticketPrice,
            startTime: block.timestamp,
            endTime: endTime,
            totalTicketsSold: 0,
            totalPrize: 0,
            numberOfTicketsToBeSoldForRaffleToExecute: minTicketsRequired,
            state: RaffleState.OPEN,
            winner: address(0),
            requestId: 0
        });

        emit RaffleCreated(
            raffleId,
            msg.sender,
            nftAddress,
            tokenId,
            ticketCount,
            endTime,
            minTicketsRequired,
            ticketPrice
        );

        raffleCounter++;
    }

    /**
     * @dev Allows a user to purchase tickets for a raffle
     * @param raffleId ID of the raffle
     * @param numberOfTickets Number of tickets to purchase
     */
    function purchaseTickets(uint256 raffleId, uint256 numberOfTickets) external payable nonReentrant whenNotPaused {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.OPEN) revert Raffle__RaffleNotActive();
        if (block.timestamp > raffle.endTime) revert Raffle__RaffleHasEnded();
        if (raffle.totalTicketsSold + numberOfTickets > raffle.ticketCount) revert Raffle__NotEnoughTickets();
        if (msg.value != numberOfTickets * raffle.ticketPrice) revert Raffle__NotEnoughEthSent();
        if (numberOfTickets > MAX_TICKET_PURCHASES_PER_BATCH) revert Raffle__TooManyTicketsInOneTransaction();

        _processTicketPurchase(raffleId, numberOfTickets);
    }
    
    /**
     * @dev Helper function to process ticket purchase
     */
    function _processTicketPurchase(uint256 raffleId, uint256 numberOfTickets) private {
        RaffleInfo storage raffle = raffles[raffleId];
        
        // Update ticket data structures
        uint256 startIndex = raffle.totalTicketsSold;
        for (uint256 i = 0; i < numberOfTickets; i++) {
            raffleTickets[raffleId][startIndex + i] = msg.sender;
        }
        
        // If this is user's first purchase in this raffle, add to participants list
        if (userTicketCounts[raffleId][msg.sender] == 0) {
            raffleParticipants[raffleId].push(msg.sender);
        }
        
        // Update user's ticket count
        userTicketCounts[raffleId][msg.sender] += numberOfTickets;
        
        // Update raffle stats
        raffle.totalTicketsSold += numberOfTickets;
        raffle.totalPrize += msg.value;

        emit TicketPurchased(raffleId, msg.sender, numberOfTickets, msg.value);

        // Check if raffle conditions are met to end it
        if (_shouldEndRaffle(raffle)) {
            _endRaffle(raffleId);
        }
    }

    /**
     * @dev Internal function to check if a raffle should end
     * @param raffle The raffle info struct
     * @return True if the raffle should end
     */
    function _shouldEndRaffle(RaffleInfo storage raffle) internal view returns (bool) {
        return block.timestamp >= raffle.endTime || raffle.totalTicketsSold >= raffle.ticketCount;
    }

    /**
     * @dev Internal function to end a raffle and initiate winner selection if conditions are met
     * @param raffleId ID of the raffle
     */
    function _endRaffle(uint256 raffleId) internal {
        RaffleInfo storage raffle = raffles[raffleId];
        raffle.state = RaffleState.PENDING_WINNER;
        
        // Only request a winner if minimum tickets were sold
        if (raffle.totalTicketsSold >= raffle.numberOfTicketsToBeSoldForRaffleToExecute) {
            requestRandomWinner(raffleId);
        }
    }

    /**
     * @dev Public function to finalize a raffle that has ended
     * @param raffleId ID of the raffle
     */
    function finalizeRaffle(uint256 raffleId) external nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.OPEN) revert Raffle__RaffleNotInOpenState();
        if (block.timestamp <= raffle.endTime && raffle.totalTicketsSold < raffle.ticketCount) 
            revert Raffle__RaffleStillActive();
            
        _endRaffle(raffleId);
    }

    /**
     * @dev Requests a random winner for a raffle from Chainlink VRF
     * @param raffleId ID of the raffle
     */
    function requestRandomWinner(uint256 raffleId) public {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.PENDING_WINNER) revert Raffle__RaffleNotPendingWinner();
        if (raffle.totalTicketsSold == 0) revert Raffle__NoTicketsPurchased();
        if (raffle.requestId != 0) revert Raffle__RequestAlreadyExists();

        uint256 requestId = _requestRandomWords();
        
        raffle.requestId = requestId;
        s_requestIdToRaffleId[requestId] = raffleId;
        
        emit RandomWordsRequested(raffleId, requestId);
    }

    /**
     * @dev Internal function to request random words from Chainlink VRF
     * @return requestId The ID of the VRF request
     */
    function _requestRandomWords() internal returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        s_requests[requestId] = RequestStatus({
            fulfilled: false,
            exists: true,
            randomWords: new uint256[](0)
        });

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    /**
     * @dev Callback function called by Chainlink VRF when random words are ready
     * @param requestId ID of the VRF request
     * @param randomWords Array of random words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override nonReentrant {
        if (!s_requests[requestId].exists) revert Raffle__RequestNotFound();
        
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWords = randomWords;

        uint256 raffleId = s_requestIdToRaffleId[requestId];
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.PENDING_WINNER) revert Raffle__RaffleNotPendingWinner();

        // Process the winner selection and payouts
        _processWinnerSelection(raffleId, randomWords[0]);
    }
    
    /**
     * @dev Helper function to process winner selection and payouts
     */
    function _processWinnerSelection(uint256 raffleId, uint256 randomWord) private {
        RaffleInfo storage raffle = raffles[raffleId];
        
        // Select winner
        uint256 winnerIndex = randomWord % raffle.totalTicketsSold;
        address winner = raffleTickets[raffleId][winnerIndex];
        raffle.winner = winner;
        raffle.state = RaffleState.COMPLETED;

        // Process payments and NFT transfer
        _processWinnerPayouts(raffleId, winner);
    }
    
    /**
     * @dev Helper function to process winner payouts and NFT transfer
     */
    function _processWinnerPayouts(uint256 raffleId, address winner) private {
        RaffleInfo storage raffle = raffles[raffleId];
        
        // Calculate fees and prize
        uint256 fee = (raffle.totalPrize * PLATFORM_FEE_PERCENTAGE) / 100;
        uint256 payout = raffle.totalPrize - fee;

        // Transfer prize to winner (following checks-effects-interactions pattern)
        (bool success1, ) = winner.call{value: payout}("");
        if (!success1) revert Raffle__PayoutFailed();

        // Transfer fee to platform wallet
        (bool success2, ) = i_platformWallet.call{value: fee}("");
        if (!success2) revert Raffle__FeeSendFailed();

        // Transfer NFT to winner
        _transferNFTToWinner(raffle.nftAddress, raffle.tokenId, winner);

        emit WinnerSelected(raffleId, winner, payout);
        emit PlatformFeeReceived(raffleId, fee);
    }
    
    /**
     * @dev Helper function to transfer NFT to winner
     */
    function _transferNFTToWinner(address nftAddress, uint256 tokenId, address winner) private {
        try IERC721(nftAddress).transferFrom(address(this), winner, tokenId) {
            // NFT transfer successful
        } catch {
            revert Raffle__NFTTransferFailed();
        }
    }

    /**
     * @dev Cancels a raffle if minimum tickets haven't been sold after end time
     * @param raffleId ID of the raffle
     */
    function cancelRaffle(uint256 raffleId) external nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.PENDING_WINNER && raffle.state != RaffleState.OPEN) 
            revert Raffle__RaffleCannotBeCancelled();
        if (block.timestamp <= raffle.endTime && raffle.state == RaffleState.OPEN) 
            revert Raffle__RaffleStillActive();
            
        // Check if minimum tickets were sold
        if (raffle.totalTicketsSold < raffle.numberOfTicketsToBeSoldForRaffleToExecute) {
            _processCancellation(raffleId);
        } else {
            // If minimum tickets were sold but raffle is in PENDING_WINNER state,
            // request the random winner if not already requested
            if (raffle.requestId == 0) {
                requestRandomWinner(raffleId);
            }
        }
    }
    
    /**
     * @dev Helper function to process raffle cancellation
     */
    function _processCancellation(uint256 raffleId) private {
        RaffleInfo storage raffle = raffles[raffleId];
        raffle.state = RaffleState.CANCELED;
        
        // Return NFT to owner
        try IERC721(raffle.nftAddress).transferFrom(address(this), raffle.owner, raffle.tokenId) {
            emit NFTReturned(raffleId, raffle.owner, raffle.nftAddress, raffle.tokenId);
        } catch {
            revert Raffle__NFTTransferFailed();
        }
        
        // Issue refunds to all participants
        _refundAllParticipants(raffleId);
        
        emit RaffleCancelled(raffleId, "Minimum tickets not sold");
    }

    /**
     * @dev Internal function to refund all participants of a cancelled raffle
     * @param raffleId ID of the raffle
     */
    function _refundAllParticipants(uint256 raffleId) internal {
        RaffleInfo storage raffle = raffles[raffleId];
        address[] memory participants = raffleParticipants[raffleId];
        
        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            uint256 ticketCount = userTicketCounts[raffleId][participant];
            
            if (ticketCount > 0) {
                uint256 refundAmount = ticketCount * raffle.ticketPrice;
                userTicketCounts[raffleId][participant] = 0;
                
                (bool success, ) = participant.call{value: refundAmount}("");
                if (!success) revert Raffle__RefundFailed();
                
                emit TicketsRefunded(raffleId, participant, refundAmount);
            }
        }
    }

    /**
     * @dev Manually trigger refunds for a specific participant
     * @param raffleId ID of the raffle
     * @param participant Address of the participant to refund
     */
    function refundParticipant(uint256 raffleId, address participant) external onlyContractOwner nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.CANCELED) revert Raffle__RaffleCannotBeCancelled();
        
        uint256 ticketCount = userTicketCounts[raffleId][participant];
        if (ticketCount == 0) revert Raffle__NoTicketsToRefund();
        
        uint256 refundAmount = ticketCount * raffle.ticketPrice;
        userTicketCounts[raffleId][participant] = 0;
        
        (bool success, ) = participant.call{value: refundAmount}("");
        if (!success) revert Raffle__RefundFailed();
        
        emit TicketsRefunded(raffleId, participant, refundAmount);
    }

    /**
     * @dev Gets the details of a raffle
     * @param raffleId ID of the raffle
     * @return raffle The raffle information
     */
    function getRaffleInfo(uint256 raffleId) external view returns (RaffleInfo memory) {
        if (raffleId >= raffleCounter) revert Raffle__RaffleDoesNotExist();
        return raffles[raffleId];
    }

    /**
     * @dev Gets the status of a VRF request
     * @param requestId ID of the VRF request
     * @return fulfilled Whether the request has been fulfilled
     * @return randomWords The random words received
     */
    function getRequestStatus(uint256 requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        if (!s_requests[requestId].exists) revert Raffle__RequestNotFound();
        RequestStatus memory req = s_requests[requestId];
        return (req.fulfilled, req.randomWords);
    }

    /**
     * @dev Gets the user's ticket count for a specific raffle
     * @param raffleId ID of the raffle
     * @param user Address of the user
     * @return Number of tickets owned by the user
     */
    function getUserTicketCount(uint256 raffleId, address user) external view returns (uint256) {
        return userTicketCounts[raffleId][user];
    }

    /**
     * @dev Gets all participants of a raffle
     * @param raffleId ID of the raffle
     * @return List of participant addresses
     */
    function getRaffleParticipants(uint256 raffleId) external view returns (address[] memory) {
        return raffleParticipants[raffleId];
    }
    
    /**
     * @dev Updates the callback gas limit for VRF requests
     * @param newGasLimit New gas limit
     */
    function updateCallbackGasLimit(uint32 newGasLimit) external onlyContractOwner {
        uint32 oldLimit = callbackGasLimit;
        callbackGasLimit = newGasLimit;
        emit CallbackGasLimitUpdated(oldLimit, newGasLimit);
    }
    
    /**
     * @dev Pause the contract in case of emergency
     */
    function pause() external onlyContractOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyContractOwner {
        _unpause();
    }

    /**
     * @dev Check if a raffle is active and can receive ticket purchases
     * @param raffleId ID of the raffle
     * @return True if the raffle is active
     */
    function isRaffleActive(uint256 raffleId) external view returns (bool) {
        RaffleInfo storage raffle = raffles[raffleId];
        return raffle.state == RaffleState.OPEN && 
               block.timestamp <= raffle.endTime &&
               raffle.totalTicketsSold < raffle.ticketCount;
    }
}

