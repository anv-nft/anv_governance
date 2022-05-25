const ANV = artifacts.require("ANVToken");
const NFT = artifacts.require("ANV_NFT");
const gorvernance = artifacts.require("KANV_Gorvanance");


contract("gorvernance", (accounts) => {
  it('setup', async () => {
    const ANVInstance = await ANV.deployed();
    const NFTInstance = await NFT.deployed();
    const GovInstance = await gorvernance.deployed();
    
    const accountOne = accounts[0];
    const accountTwo = accounts[1];

    await ANVInstance.mintToken(accountTwo, 10000);
    await ANVInstance.mintToken(accountOne, 3000);
    
    for (step = 0; step < 5; step++) {
      const a = await NFTInstance.mint(accountOne, step, ANVInstance.address);
      const b = await NFTInstance.mint(accountTwo, step+5 ,ANVInstance.address);
      
      // Runs 5 times, with values of step 0 through 4.
      // console.log('Walking east one step');
    }
  });


  it('check the move', async () => {
    const ANVInstance = await ANV.deployed();
    const NFTInstance = await NFT.deployed();
    const GovInstance = await gorvernance.deployed();
    const accountOne = accounts[0];
    const accountTwo = accounts[1];

    // 소각 및 홀딩을 위한 사전 준비
    await ANVInstance.approve(GovInstance.address,2000, { from: accountOne });
    for (step = 0; step < 5; step++) {
      await NFTInstance.approve(GovInstance.address, step, {from: accountOne});
    }
    const NFTs = await [0,1,2,3,4]
    await GovInstance.move('hi', 'hihi', NFTs, NFTInstance.address, ANVInstance.address, {from:accountOne});
    // GovInstance.checkMove.call(1);
    // const balance = await ANVInstance.balanceOf.call(accountOne)
    const item = await GovInstance.checkItem.call(1)


    // console.log(balance);
  });

  it('check the votes and close', async () => {
    const ANVInstance = await ANV.deployed();
    const NFTInstance = await NFT.deployed();
    const GovInstance = await gorvernance.deployed();
    const accountOne = accounts[0];
    const accountTwo = accounts[1];
    // await ANVInstance.approve(GovInstance.address,1000, { from: accountOne });
    // await ANVInstance.approve(GovInstance.address,1000, { from: accountTwo });
    console.log(GovInstance.address, accountOne);
    // await NFTInstance.approve(GovInstance.address,0, { from: accountOne });
    await NFTInstance.approve(GovInstance.address,5, { from: accountTwo });

    // await GovInstance.votes(1, 1000, true, 0, NFTInstance.address, ANVInstance.address, {from:accountOne});
    await GovInstance.votes(1, 1000, 1000,true, 5, NFTInstance.address, ANVInstance.address, {from:accountTwo});
    await GovInstance.closeVotes(1, ANVInstance.address,NFTInstance.address);
    
    const Item = await GovInstance.checkItem.call(1);
    console.log(Item);
  });
  // it('check the votes to closed item', async () => {
  //   const GovInstance = await gorvernance.deployed();
  //   const accountOne = accounts[0];

  //   GovInstance.move('hihi','hihi',{from:accountOne})
    

  // });


});
