// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./token/IERC721.sol";
import "./token/IERC20.sol";
import "./library/PRBMathUD60x18.sol";

import "./access/Ownable.sol";
import "./gsn/Context.sol";
import "./address/Address.sol";
import "./strings/Strings.sol";

contract KANV_Gorvanance {

  address public erc20Token;
  address public erc721NFT;
  uint256 public feeAmount;

  address  public governance;
  address tokenAddress;
  address NFTAddress;

  struct moveItem {
    address mover; //발의인
    uint256[] holidingTokenIds;

    string title; //발의명
    string content; //발의안
    uint movedBlockNumber; // 시간 확인을 위한 발의 시 블록넘버
    bool isActive; // 활성화여부
    bool isApproved; // 통과여부

    uint256 pros; //찬성
    uint256 cons; //반대
    address[] voterList;
  }

  mapping(uint256 => moveItem) moveItems; //발의호수
  uint256 totalMove; // 총 발의안 수

  struct voterInfo {
    uint256 holdingTokenId;
    bool prosAndCons;
    uint256 voting; // == holdingTokenAmount
  }

  mapping(uint256 => mapping(address => voterInfo)) voter;


  event TokenPlaced(uint256 indexed tokenId,  uint256 cost);
  event TokenUnplaced(uint256 indexed tokenId);
  event TokenSold(uint256 indexed tokenId, address indexed newOwner);
  event checkthis(address approvedaddress, address thisaddress);
  event BalanceCheck(uint256 _balance);

  event ErrorCheck(address a, address b);
  constructor (address _erc20Token,address _erc721NFT, address _governance) {
    totalMove = 1;
    erc20Token = _erc20Token;
    erc721NFT = _erc721NFT;
    governance = _governance;
  }

  function move(string memory title, string memory content, uint256[] memory tokenIds, address ERC721NFT, address ERC20TOKEN) external  {
    // require(ERC20TOKEN == erc20Token,'a');
    // require(ERC721NFT == erc721NFT,'b');
    
    // 발의 시 고려해야 할 사항 : (1) 1.b, (2) 1.c, (3) 2.a, (4) 4
    // 발의 조건 : (1) 1.b - NFT 5개 이상
    require(IERC20(ERC20TOKEN).balanceOf(msg.sender) >= 2000, "not enough KANV");
    require(IERC721(ERC721NFT).balanceOf(msg.sender) >= 5, "not enough NFT");
  
    // 그외 고려 조건 : 의제의 정상 여부 판단(주제 및 내용 텍스트 존재 여부)
    require(bytes(title).length > 0 && bytes(content).length > 0,"The title and content must be filled");


    // 발의를 위한 상태 : (2) 1.c, (4) 4 - NFT 홀딩
    for(uint i=0; i<5; i++){
        require(IERC721(ERC721NFT).ownerOf(tokenIds[i]) == msg.sender,"Unvailed Token Owner");  
    }
    for(uint i=0; i<5; i++){
        IERC721(ERC721NFT).transferFrom(msg.sender, address(this), tokenIds[i]);
    }

    // (3) 2.a - 발의시 2000KANV 소각(재단지갑 이동 후, 재단에서 소각)
    IERC20(ERC20TOKEN).transferFrom(msg.sender, address(this), 2000);
    // 소각 양 기록하는 변수 추가 고려
    // 발의 처리 
    address[] memory blankAddressList;


    moveItems[totalMove] = (moveItem(msg.sender, tokenIds, title, content, block.number, true, false, 0, 0, blankAddressList));
    totalMove += 1;
  }

  function votes(uint256 index, uint256 voting, uint256 voteSnapshot, bool yesOrNo, uint256 tokenid, address ERC721NFT, address ERC20TOKEN) external {
    // require(ERC20TOKEN == erc20Token);
    // require(ERC721NFT == erc721NFT);
    
    require(voter[index][msg.sender].voting == 0, 'You Voted');

      // 정상 작동 여부 검토
      // 의제 활성화 여부 확인
      require(moveItems[index].isActive == true, "Deactivated Item");
      // 투표 철회 및 추가 투표 어떻게 처리 할 것인지?
      // require(voter[index][msg.sender] == false, "You Voted");

      // 조건 : (1) 1.a, (2) 1.c, (3) 3, (4) 4, (5) 5,
      // (1) 1.a - NFT 1개 이상이 참여권
      // require(IERC721(ERC721NFT).balanceOf(msg.sender) >= 1, "not enough NFT");
      
      emit ErrorCheck(IERC721(ERC721NFT).ownerOf(tokenid), msg.sender);
      
      // require(IERC721(ERC721NFT).ownerOf(tokenid) == msg.sender,"Unvailed Token Owner");  

      // (3) 3 - 투표권은 KANV 기준
      // require(IERC20(ERC20TOKEN).balanceOf(msg.sender) >= voting, "Exceed the number of votes");
      // 4.a 스냅샷 기준
      require(voting <= voteSnapshot, 'More than snapshot');
 

      // (2) 1.c - 투표가 진행되는동안 NFT와 KANV 가 홀딩되어 있어야 한다.
      // (4) 4 - 투표가 진행되는 동안 NFT와 KAV가 홀딩
      IERC20(ERC20TOKEN).transfer(address(this), voting);
      IERC721(ERC721NFT).transferFrom(msg.sender, address(this), tokenid);

      // (5) 5 투표가 끝나면 발의자를 제외한 투표자들의 토큰은 상환
      // 이를 위한 변수 추가
      voter[index][msg.sender].holdingTokenId = tokenid;
      voter[index][msg.sender].voting = voting;
      moveItems[index].voterList.push(msg.sender);

      if (yesOrNo == true){
          moveItems[index].pros += voting;
          voter[index][msg.sender].prosAndCons = true;

      } else {
          moveItems[index].cons += voting;
          voter[index][msg.sender].prosAndCons = false;

      }
    }

  function closeVotes(uint256 index, address ERC20TOKEN, address ERC721NFT) external {
    // require(ERC20TOKEN == erc20Token);
    // require(ERC721NFT == erc721NFT);
    // 조건 : (1) 5, (2) 7.a,
      // 최소 참여 기준 설정(해당 투표 시작 당시 KANV 대비 일정 퍼센트 이상의 투표가 발생해야 유효한 투표로 인정할지)
    moveItem memory item = moveItems[index];
    require(item.isActive == true,"Deactivated item");
    // 클레이튼 1블록 1초, 원하는 투표 기간만큼 아래 괄호에 삽입
    require(item.movedBlockNumber + (0)<= block.number,"not yet");

    // (2) 7.a : 해당 의제의 최소 참여 기준 설정, 일정 퍼센트 이상이 투표해야 유효 투표임을 인정
    // bool turnout = PRBMathUD60x18.div(
    //   (item.pros + item.cons), 
    //   (IERC20(erc20Token).totalSupply() - IERC20(erc20Token).balanceOf(governance))
    //   ) >= 300000000000000000;
    bool turnout = true; // test
    //(1) 5 투표가 끝나면 발의자를 제외한 투표자들의 토큰은 상환
    if (turnout == false){
      // 투표 유효하지 않으면 비활성화 시키고 상환하며 종료
        for(uint i=0; i < moveItems[index].voterList.length; i++){
          moveItems[index].isActive = false;

          IERC20(ERC20TOKEN).transfer(moveItems[index].voterList[i], voter[index][moveItems[index].voterList[i]].voting);
          IERC721(ERC721NFT).transferFrom(address(this), moveItems[index].voterList[i], voter[index][moveItems[index].voterList[i]].holdingTokenId);
        }
    } else if (turnout == true && item.pros > item.cons){
      //투표 유효하고, 찬성이 더 많으면, 투표 종료 및 통과
        moveItems[index].isActive = false;
        moveItems[index].isApproved = true;

        for(uint i=0; i < moveItems[index].voterList.length; i++){
          IERC20(ERC20TOKEN).transfer(moveItems[index].voterList[i], voter[index][moveItems[index].voterList[i]].voting);
          IERC721(ERC721NFT).transferFrom(address(this), moveItems[index].voterList[i], voter[index][moveItems[index].voterList[i]].holdingTokenId);

        }

    }  else if (item.pros < item.cons){
      //반대가 더 많으면, 투표 종료 및 반대 
      // 투표 유효하지 않을 시 어차피 통과되지 않으므로 조건식에 포함하지 않음

        moveItems[index].isActive = false;
        for(uint i=0; i < moveItems[index].voterList.length; i++){
          IERC20(ERC20TOKEN).transfer(moveItems[index].voterList[i], voter[index][moveItems[index].voterList[i]].voting);
          IERC721(ERC721NFT).transferFrom(address(this), moveItems[index].voterList[i], voter[index][moveItems[index].voterList[i]].holdingTokenId);

        }
    } else if (turnout == true && item.pros == item.cons){
      // 찬반 같으면 투표 1일 연장
      // 투표 유효성에 따라 결정?
        moveItems[index].movedBlockNumber += 3600*24; // 찬반 같은경우 1일 연장?


    }

  }

  function revocation(uint256 index, address ERC20TOKEN, address ERC721NFT) public {
  // 6.a. 투표를 수행 후 철회 가능하지만, 투표 종료 직전에 불가능
  // 괄호에 철회 기한을 삽입. 6일이면 3600 * 24 * 6
    require(moveItems[index].movedBlockNumber + (0) >= block.number,"Time limit reached");
    require(moveItems[index].isActive == true, "Not Active Move"); 

    IERC20(ERC20TOKEN).transferFrom(address(this), msg.sender, voter[index][msg.sender].voting);
    IERC721(ERC721NFT).transferFrom(address(this), msg.sender, voter[index][msg.sender].holdingTokenId);
    if (voter[index][msg.sender].prosAndCons == true){
      moveItems[index].pros -= voter[index][msg.sender].voting;
      
    } else {
      moveItems[index].cons -= voter[index][msg.sender].voting;
    }
    voter[index][msg.sender].voting = 0;
    voter[index][msg.sender].holdingTokenId = 0;


  }


  function checkMove(uint256 index) public view returns (uint256, uint256){
    return (moveItems[index].pros, moveItems[index].cons);
  }

  function checkActive(uint256 index) public view returns (bool){
    return (moveItems[index].isActive == true);
  }

  function checkEnd(uint256 index) public view returns (bool){
    return (moveItems[index].movedBlockNumber + (3600 * 24 * 7)>= block.number);
  }

  function checkItem(uint256 index) public view returns (moveItem memory){
    return moveItems[index];
  }


}
