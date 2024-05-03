import React, { useState } from 'react';
import './Display.css';

const Display = ({ contract, account }) => {
  const [images, setImages] = useState([]);
  const [inputAddress, setInputAddress] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  const handleInputChange = (event) => {
    setInputAddress(event.target.value);
  };

  const getImages = async () => {
    try {
      console.log('Logged-in account:', account);
      console.log('Entered address:', inputAddress);
      
      const imageData = await contract.display(inputAddress || account);
      
      // Check if the returned data is empty
      if (imageData.length === 0) {
        alert("No images found.");
        return;
      }
      
      const imageElements = [];
  
      for (let i = 0; i < imageData.length; i++) {
        // Split the string to get the IPFS hash
        const parts = imageData[i].split("gateway.pinata.cloud/ipfs/");
        const ipfsHash = parts[1];
  
        // Construct the URL with the IPFS hash
        const imageUrl = `https://gateway.pinata.cloud/ipfs/${ipfsHash}`;
  
        // Fetch image data
        const response = await fetch(imageUrl);
        if (!response.ok) {
          throw new Error(`Failed to fetch image: ${response.statusText}`);
        }
  
        // Convert image data to blob
        const blob = await response.blob();
        const imageUrlObject = URL.createObjectURL(blob);
  
        // Create image element
        imageElements.push(
          <div key={i} className="image-container">
            <img src={imageUrlObject} alt={`Image ${i}`} className="image" />
          </div>
        );
      }
  
      setImages(imageElements);
    } catch (error) {
      console.error('Error fetching images:', error);
      if (error.reason === "You don't have access") {
        alert("You don't have access to view images of this address.");
      } else {
        alert('Failed to fetch images.');
      }
    }
  };
  
  

  return (
    <div>
      <input 
        type="text" 
        placeholder="Enter Address" 
        className="address" 
        value={inputAddress} 
        onChange={handleInputChange} 
      />
      <button className="center button" onClick={getImages}>
        Get Images
      </button>
      {errorMessage && <div className="error-message">{errorMessage}</div>}
      <div className="image-list">{images}</div>
    </div>
  );
};

export default Display;
