const pinataSDK = require("@pinata/sdk");

require("dotenv").config();
const pinata = pinataSDK(
  process.env.Pinata_API_Key,
  process.env.Pinata_API_Secret
);
//Test authentication of Api Key and Secret
pinata
  .testAuthentication()
  .then((result) => {
    //handle successful authentication here
    console.log(result);
  })
  .catch((err) => {
    //handle error here
    console.log(err);
  });

const sourcePath = "./metadata";

pinata
  .pinFromFS(sourcePath)
  .then((result) => {
    //handle results here
    console.log(result);
  })
  .catch((err) => {
    //handle error here
    console.log(err);
  });


