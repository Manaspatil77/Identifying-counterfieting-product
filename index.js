var contractABI = null;
var contractAddress = null;
var account0 = null;
var AssetTrackerContract = null;
$.ajax({
    url: "./build/contracts/AssetTracker.json",
    async: false,
    dataType: "json",
    delay: 500,
    success: function(json) {
        assignVariable(json);
    }
});

function assignVariable(data) {
    contractABI = data.abi;
    contractAddress = data.networks[5777].address;
}

web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:7545"));

// const checkCurrentAccount = () => {
//     if (window.ethereum) {
//       window.ethereum.on("accountsChanged", async () => {
//        const accounts = await window.ethereum.request({
//          method: "eth_accounts",
//        });
//        setCurrentAccount(accounts[0]);
//      });
//     }
//    };
   
//    useEffect(() => {
//     checkCurrentAccount();
//    }, []);

web3.eth.getAccounts().then(function(result) {
    account0 = result[9];
    console.log(result);
});

setTimeout(function delay() {
    AssetTrackerContract = new web3.eth.Contract(
        contractABI,
        contractAddress, { from: window.ethereum.selectedAddress, gas: 3000000 }
    );
}, 1000);


setTimeout(function delay() {
    console.log(window.ethereum.selectedAddress);
    Object.freeze(window.ethereum.selectedAddress);
}, 4000);