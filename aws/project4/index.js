const AWS = require("aws-sdk");

// Initialize AWS clients
const comprehend = new AWS.Comprehend();
const translate = new AWS.Translate();
const rekognition = new AWS.Rekognition();
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Bedrock client: example placeholder, adjust with actual SDK when available
// const bedrock = new AWS.Bedrock(); // Hypothetical

exports.handler = async (event) => {
  console.log("Received event:", JSON.stringify(event));

  const body = JSON.parse(event.body);
  const sessionId = body.sessionId || "default-session";
  let userText = body.text || "";
  const voiceBase64 = body.voice || null;
  const imageBase64 = body.image || null;

  // 1. Translate text to English if needed
  let translatedText = userText;
  if (userText) {
    const translateResult = await translate.translateText({
      Text: userText,
      SourceLanguageCode: "auto",
      TargetLanguageCode: "en"
    }).promise();
    translatedText = translateResult.TranslatedText;
  }

  // 2. Analyze sentiment with Comprehend
  const sentimentData = await comprehend.detectSentiment({
    LanguageCode: "en",
    Text: translatedText
  }).promise();

  // 3. Analyze image if provided
  let imageLabels = [];
  if (imageBase64) {
    const imageBuffer = Buffer.from(imageBase64, "base64");
    const rekogResult = await rekognition.detectLabels({
      Image: { Bytes: imageBuffer },
      MaxLabels: 5,
      MinConfidence: 70
    }).promise();
    imageLabels = rekogResult.Labels.map(l => l.Name);
  }

  // 4. Generate response from Bedrock (simulated here)
  const bedrockResponse = `Simulated Bedrock reply based on text: "${translatedText}" and image labels: [${imageLabels.join(", ")}] with sentiment: ${sentimentData.Sentiment}`;

  // 5. Save chat log in DynamoDB
  await dynamodb.put({
    TableName: "ChatLogs",
    Item: {
      sessionId: sessionId,
      timestamp: Date.now(),
      userText: userText,
      translatedText: translatedText,
      sentiment: sentimentData.Sentiment,
      imageLabels: imageLabels,
      botResponse: bedrockResponse
    }
  }).promise();

  // 6. Return response
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      reply: bedrockResponse,
      sentiment: sentimentData.Sentiment,
      imageLabels: imageLabels
    })
  };
};
