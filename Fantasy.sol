//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

//Control who can access various functions.
contract AccessControl {
    address payable public creatorAddress;
    uint16 public totalDirectors = 0;
    mapping (address => bool) public directors;

   modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, "You are not the creator of the contract.");
        _;
    }

    modifier onlyDIRECTORS() {
      require(directors[msg.sender] == true,  "You do not have the proper permissions.");
        _;
    }
   // Constructor
    constructor() {
        creatorAddress = msg.sender;
    }

    function addDirector(address _newDirector) onlyCREATOR public {
        if (directors[_newDirector] == false) {
            directors[_newDirector] = true;
            totalDirectors += 1;
        }
    }

    function removeDirector(address _oldDirector) onlyCREATOR public {
        if (directors[_oldDirector] == true) {
            directors[_oldDirector] = false;
            totalDirectors -= 1;
        }
    }
}

abstract contract ITACData {
    function balanceOf(address account) public virtual view returns (uint256) ;
    function transfer(address recipient, uint256 amount) public virtual returns (bool) ;
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
}

// Main Contract
contract Fantasy is AccessControl {

struct MedalStand {
    address first;
    address second;
    address third;
    address fourth;
}

struct League {
   uint64 id;
   uint64 liveTime; //live time is also used to tell if the league is live. 
   uint64 closeTime;
   bool isPublic; 
   uint256 price; 
}

//Main array to store all league info. 
League [] public allLeagues;

//Store key contract level variables
uint64 public numLeagues;
uint8 public maxPlayers =  20;
address public TACContract = address(0);
bool public contractInitialized = false;

//Store which leagues each player is in. 
mapping (address => uint64 [] ) leaguesForPlayer;

//Store the players and permitted players for each league. 
mapping(uint64 => address[]) public playersForLeague;
mapping(uint64 => address[]) public permittedPlayersForLeague;

//Store which players have won which league
mapping(uint64 => MedalStand) public winnersForLeague;

function setTACContract(address _TACContract) public onlyCREATOR {
    TACContract = _TACContract;
}

//Function called once to initialize and create the first league.
function init() public onlyCREATOR {
        require(contractInitialized == false, "This contract has already been initialized");
        League memory league;
        league.id = 0;
        league.liveTime = uint64(block.timestamp);
        numLeagues++;
        allLeagues.push(league);
        contractInitialized = true;
}

function createLeague(uint64 liveTime, uint64 closeTime, uint256 price, bool isPublic) public {
    
        // Check that the caller has enough TAC to open a league and charge them 
        ITACData TAC = ITACData(TACContract);
        require(TAC.balanceOf(msg.sender) >= price, "You must have enough TAC to create that league.");
        TAC.transferFrom(msg.sender, address(this), price);
        
        //Create the league.
        League memory league;
        league.id = uint64(numLeagues);
        league.liveTime = liveTime;
        league.closeTime = closeTime;
        league.isPublic = isPublic;
        league.price = price;
        
        //Add the player to the league
        playersForLeague[numLeagues].push(msg.sender);
        leaguesForPlayer[msg.sender].push(numLeagues);
        
        //Add the league and increment. 
        allLeagues.push(league);
        numLeagues ++;
}

//Must be called by the person who made the league, if he wanted it to be private. 
function addPermittedPlayers(uint64 id, address newPlayer1, address newPlayer2, address newPlayer3) public {
    require(permittedPlayersForLeague[id][0] == msg.sender, "Only the person who created the league can add permitted players");
    require(permittedPlayersForLeague[id].length <= (maxPlayers - 3), "This league is already full");
    permittedPlayersForLeague[id].push(newPlayer1);
    permittedPlayersForLeague[id].push(newPlayer2);
    permittedPlayersForLeague[id].push(newPlayer3);
}

function joinLeague(uint64 id) public  {
    ITACData TAC = ITACData(TACContract);
    bool permitted = true;
    // Check if the league is public or private
    // If private, check if the sender is on the permitted players list.
    if (allLeagues[id].isPublic == false) {
        for (uint8 i=0; i< maxPlayers; i ++) {
             if (permittedPlayersForLeague[id][i] == msg.sender) {
                 permitted = true;
             }
        }
    }
    
    // Verify joining conditions are met. 
    require(permitted == true, "You aren't allowed to join this league.");
    require(TAC.balanceOf(msg.sender) >= allLeagues[id].price, "You must have enough TAC to join that league.");
    require(playersForLeague[id].length <= maxPlayers, "This league is already full");
    require(allLeagues[id].closeTime > uint64(block.timestamp), "This league is already done.");
     
    // Transfer the player's TAC to the league. 
    TAC.transferFrom(msg.sender, address(this), allLeagues[id].price);
    
    // Finally, add the player to the league. 
    playersForLeague[id].push(msg.sender);
    leaguesForPlayer[msg.sender].push(id);
}

// Admin function called when an athlete would like to remove his share of TAC. 
// Athletes sign messages in the web app, our server calls this function. 
function payAthlete(address athlete, uint256 amount) public onlyDIRECTORS {
      ITACData TAC = ITACData(TACContract);
      TAC.transfer(athlete, amount);
}

// Admin function called to pay out a league
function closeLeague(uint64 id, address winner1, address winner2, address winner3, address winner4, uint256 payout1, uint256 payout2, uint256 payout3, uint256 payout4 ) public onlyDIRECTORS {
    require(uint64(block.timestamp) > allLeagues[id].closeTime, "It isn't time to close the league yet");
   
    // Pay the winners
    ITACData TAC = ITACData(TACContract);
    TAC.transfer(winner1, payout1);
    TAC.transfer(winner2, payout2);
    TAC.transfer(winner3, payout3);
    TAC.transfer(winner4, payout4);
    
    // Record the winners
    winnersForLeague[id].first = winner1;
    winnersForLeague[id].second = winner2;
    winnersForLeague[id].third = winner3;
    winnersForLeague[id].fourth = winner4;
}

// Returns all the information about the specified league
function getLeague(uint64 id) public view returns (uint64 liveTime, uint64 closeTime, address[] memory permittedPlayers, address[] memory players, uint256 price, address winner1, address winner2, address winner3, address winner4) {
  liveTime = allLeagues[id].liveTime;
  closeTime = allLeagues[id].closeTime;
  permittedPlayers = permittedPlayersForLeague[id];
  players= playersForLeague[id];
  price= allLeagues[id].price;
  winner1 = winnersForLeague[id].first;
  winner2 = winnersForLeague[id].second;
  winner3 = winnersForLeague[id].third;
  winner4 = winnersForLeague[id].fourth;
}

}
