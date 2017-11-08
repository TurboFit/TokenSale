pragma solidity ^0.4.18;

contract SafeMath {
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Ownable {

    address public owner;
    address public pendingOwner;

    function Ownable() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /* Allows the current owner to set the pendingOwner address. */
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }
    /* Allows the pendingOwner address to finalize the transfer. */
    function claimOwnership() public {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
        pendingOwner = 0x0;
    }
}
contract StandardTokenERC20 is SafeMath {

    uint256 public totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;}
interface tokenERC20 {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract TurboFitToken is StandardTokenERC20, Ownable {
    string public constant name = "TurboFit Token";
    string public constant symbol = "TFT";
    uint256 public constant decimals = 18;

    function TurboFitToken() public {
        totalSupply = 210000000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function() public {
        revert();
    }

    /* Approve and then communicate the approved contract in a single tx */
    /* Сall the receiveApproval function on the contract you want to be notified. */
    /* This crafts the function signature manually so one doesn't have to include a contract in here just for this. */
    /* receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData) */
    /* it is assumed when one does this that the call *should* succeed, otherwise one would use vanilla approve instead. */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* Reclaim all ERC20Basic compatible tokens */
    function reclaimToken(tokenERC20 token) onlyOwner public {
        uint256 _value = token.balanceOf(this);
        require(_value > 0);
        assert(token.transfer(msg.sender, _value));
    }

    event Burn(uint256 _value);
    function burn(uint256 _value) onlyOwner public returns (bool) {
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        totalSupply = safeSub(totalSupply, _value);
        Burn(_value);

        if (totalSupply == 0) {
            selfdestruct(msg.sender);
        }
        return true;
    }
}