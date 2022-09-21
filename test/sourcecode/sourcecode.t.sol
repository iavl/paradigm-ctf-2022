pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../src/sourcecode/Setup.sol";
import "../../src/sourcecode/Challenge.sol";

contract POC is Test {
    Setup setup;

    function setUp() public {
        setup = new Setup();
    }

    function testSolve() public {
        bytes
            memory code = hex"7f80607f60005360015260215260416000f300000000000000000000000000000080607f60005360015260215260416000f3000000000000000000000000000000";
        Challenge challenge = Challenge(setup.challenge());

        assertEq(setup.isSolved(), false);
        challenge.solve(code);
        assertEq(setup.isSolved(), true);
    }
}
