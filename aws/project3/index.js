const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  const params = {
    TableName: "ExampleTable", // must match the name in Terraform
    Item: {
      id: "123",               // hardcoded ID for simplicity
      message: "Hello from Lambda!"
    }
  };

  try {
    await dynamodb.put(params).promise();
    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Data inserted successfully!" })
    };
  } catch (err) {
    console.error("DynamoDB Error", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Could not write to DynamoDB" })
    };
  }
};
