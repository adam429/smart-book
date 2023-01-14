require 'smartbook'
require_relative './web3'

RPC_NODE = "https://eth-mainnet.g.alchemy.com/v2/xOu9KmQYmgmqBuYhhPW0naOB9YRY3foa"
ETHERSCAN_API_KEY = "545QYEP8TJKJWMZ7QP41QYXZNMJDVCJUI9"


CONTRACT_PLP_WETHICE = "0xff338d347e59d6b61e5c69382915d863bb22ef2f"

Etherscan.api_key(ETHERSCAN_API_KEY)
Web3.init_provider(RPC_NODE)

Contract.add(:popsicle,JSON.load_file("./abi/PopsicleV3Optimizer.json"),CONTRACT_PLP_WETHICE)

txs = Etherscan.getAddressTx(CONTRACT_PLP_WETHICE)
tx0 = Web3.parseTxs(txs[0]["hash"])
blockNumber = tx0.blockNumber

pool_address, token0, token1 = Thread.wait(
  ->{Contract.popsicle.pool({:blockTag=>blockNumber})},
  ->{Contract.popsicle.token0({:blockTag=>blockNumber})},
  ->{Contract.popsicle.token1({:blockTag=>blockNumber})}
)

Thread.wait(
    ->{Contract.add(:pool,Etherscan.getAbi(pool_address,"./abi/UniswapV3Pool.json"),pool_address)},
    ->{Contract.add(:token0,Etherscan.getAbi(token0,"./abi/ERC20.json"),token0)},
    ->{Contract.add(:token1,Etherscan.getAbi(token1,"./abi/ERC20.json"),token1)}
)

Thread.wait(
->{puts "popsicle: #{Contract.popsicle.name({:blockTag=>blockNumber})}" },
->{puts "token0: #{Contract.token0.name({:blockTag=>blockNumber})}" },
->{puts "token1: #{Contract.token1.name({:blockTag=>blockNumber})}" }
)

