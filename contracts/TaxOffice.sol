// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./owner/Operator.sol";
import "./interfaces/ITaxable.sol";

/*
__________                             .___   ___________.__
\______   \_____     ______  ____    __| _/   \_   _____/|__|  ____  _____     ____    ____   ____
 |    |  _/\__  \   /  ___/_/ __ \  / __ |     |    __)  |  | /    \ \__  \   /    \ _/ ___\_/ __ \
 |    |   \ / __ \_ \___ \ \  ___/ / /_/ |     |     \   |  ||   |  \ / __ \_|   |  \\  \___\  ___/
 |______  /(____  //____  > \___  >\____ |     \___  /   |__||___|  /(____  /|___|  / \___  >\___  >
        \/      \/      \/      \/      \/         \/             \/      \/      \/      \/     \/
*/
contract TaxOffice is Operator {
    address public based;

    constructor(address _based) {
        require(_based != address(0), "based address cannot be 0");
        based = _based;
    }

    function setTaxTiersTwap(uint8 _index, uint256 _value) public onlyOperator returns (bool) {
        return ITaxable(based).setTaxTiersTwap(_index, _value);
    }

    function setTaxTiersRate(uint8 _index, uint256 _value) public onlyOperator returns (bool) {
        return ITaxable(based).setTaxTiersRate(_index, _value);
    }

    function enableAutoCalculateTax() public onlyOperator {
        ITaxable(based).enableAutoCalculateTax();
    }

    function disableAutoCalculateTax() public onlyOperator {
        ITaxable(based).disableAutoCalculateTax();
    }

    function setTaxRate(uint256 _taxRate) public onlyOperator {
        ITaxable(based).setTaxRate(_taxRate);
    }

    function setBurnThreshold(uint256 _burnThreshold) public onlyOperator {
        ITaxable(based).setBurnThreshold(_burnThreshold);
    }

    function setTaxCollectorAddress(address _taxCollectorAddress) public onlyOperator {
        ITaxable(based).setTaxCollectorAddress(_taxCollectorAddress);
    }

    function excludeAddressFromTax(address _address) external onlyOperator returns (bool) {
        return ITaxable(based).excludeAddress(_address);
    }

    function includeAddressInTax(address _address) external onlyOperator returns (bool) {
        return ITaxable(based).includeAddress(_address);
    }

    function setTaxableBasedOracle(address _basedOracle) external onlyOperator {
        ITaxable(based).setBasedOracle(_basedOracle);
    }

    function transferTaxOffice(address _newTaxOffice) external onlyOperator {
        ITaxable(based).setTaxOffice(_newTaxOffice);
    }
}
