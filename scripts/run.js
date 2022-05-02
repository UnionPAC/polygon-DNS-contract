const main = async () => {
  const domainContractFactory = await hre.ethers.getContractFactory("Domains");
  const domainContract = await domainContractFactory.deploy("mango");
  await domainContract.deployed();
  console.log("Contract deployed to:", domainContract.address);

  // register domain name
  let tx = await domainContract.register("smart", {
    value: hre.ethers.utils.parseEther("0.1"),
  });
  await tx.wait();
  console.log("Minted domain smart.mango");

  // set record for domain name
  tx = await domainContract.setRecord('smart', 'A very studious fruit');
  await tx.wait();
  console.log('record set successfully!')

  // get record for domain name
  const record = await domainContract.getRecord('smart');
  console.log("Record:", record);

  // get owner address of that domain name
  const address = await domainContract.getAddress('smart');
  console.log('Owner of domain smart:', address);

  // get contract balance
  const contractBalance = await hre.ethers.provider.getBalance(domainContract.address);
  console.log('Contract balance:', hre.ethers.utils.formatEther(contractBalance));
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
