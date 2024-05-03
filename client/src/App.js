import Upload from "./artifacts/contracts/Upload.sol/Upload.json";
import { useState, useEffect } from "react";
import { ethers } from "ethers";
import FileUpload from "./components/FileUpload";
import Display from "./components/Display";
import Modal from "./components/Modal";
import "./App.css";

function PerformanceMetrics({ merkleTreeHeight, gasCost, storageEfficiency }) {
  return (
    <div className="performance-metrics">
      <h2>Performance Metrics</h2>
      <p>Merkle Tree Height: {merkleTreeHeight}</p>
      <p>Gas Cost for Verification: {gasCost}</p>
      <p>Storage Efficiency: {storageEfficiency}</p>
    </div>
  );
}

function App() {
  const [account, setAccount] = useState("");
  const [contract, setContract] = useState(null);
  const [provider, setProvider] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [merkleTreeHeight, setMerkleTreeHeight] = useState(0);
  const [gasCost, setGasCost] = useState(0);
  const [storageEfficiency, setStorageEfficiency] = useState(0);

  useEffect(() => {
    const loadBlockchainData = async () => {
      if (window.ethereum) {
        try {
          const provider = new ethers.providers.Web3Provider(window.ethereum);
          await provider.send("eth_requestAccounts", []);
          const signer = provider.getSigner();
          const address = await signer.getAddress();
          setAccount(address);
          let contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  
          const contract = new ethers.Contract(
            contractAddress,
            Upload.abi,
            signer
          );
          setContract(contract);
          setProvider(provider);
  
          const userAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
          const height = await contract.calculateMerkleTreeHeight(userAddress);
          setMerkleTreeHeight(height.toNumber());

          const tx = await contract.calculateGasCostForVerification(userAddress);
          const receipt = await provider.getTransactionReceipt(tx.hash);
          const gasUsed = receipt.gasUsed.toNumber();
          setGasCost(gasUsed);

          if (height > 0) {
            const storageEff = await contract.calculateStorageEfficiency(userAddress);
            setStorageEfficiency(storageEff.toNumber());
          }
        } catch (error) {
          console.error("Error connecting to MetaMask:", error);
        }
      } else {
        console.error("MetaMask extension not detected");
      }
    };
  
    loadBlockchainData();
  }, []);

  useEffect(() => {
    // Listen for changes in performance metrics
    // For demonstration, you can add your logic here to update the metrics whenever they change
  }, [merkleTreeHeight, gasCost, storageEfficiency]);

  return (
    <>
      {!modalOpen && (
        <button className="share" onClick={() => setModalOpen(true)}>
          Share
        </button>
      )}
      {modalOpen && (
        <Modal setModalOpen={setModalOpen} contract={contract}></Modal>
      )}

      <div className="App">
        <h1 style={{ color: "white" }}>CryptoGallery</h1>
        <div className="bg"></div>
        <div className="bg bg2"></div>
        <div className="bg bg3"></div>

        <p style={{ color: "white" }}>
          Account : {account ? account : "Not connected"}
        </p>
        <FileUpload
          account={account}
          provider={provider}
          contract={contract}
        ></FileUpload>
        <Display contract={contract} account={account}></Display>
        <PerformanceMetrics
          merkleTreeHeight={merkleTreeHeight}
          gasCost={gasCost}
          storageEfficiency={storageEfficiency}
        />
      </div>
    </>
  );
}

export default App;
