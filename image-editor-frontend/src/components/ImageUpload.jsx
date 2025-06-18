import { Heading, View, FileTrigger, Button, Flex, Text } from "@adobe/react-spectrum";
import { useState } from "react";

export default function ImageUpload({ setImageUrl, setUploadedImageId, setOriginalImageId, setUploadedFile }) {
  const [isUploading, setIsUploading] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState(null);
  const [errorMessage, setErrorMessage] = useState("");

  const handleFileUpload = async (files) => {
    if (files.length === 0) return;

    const file = files[0];
    setUploadedFile(file);

    // Check if the file is an image
    if (!file.type.startsWith("image/")) {
      setErrorMessage("Please upload a valid image file.");
      return;
    }

    const formData = new FormData();
    formData.append("image[file]", file);

    setIsUploading(true);
    setErrorMessage("");

    // Call the Rails API to save an image
    try {
      const response = await fetch("http://localhost:3000/images", {
        method: "POST",
        body: formData,
        credentials: 'include',
      });

      if (response.ok) {
        setUploadSuccess(true);
        const data = await response.json();
        setOriginalImageId(data.id);
        console.log("Image uploaded successfully:", data);

        setImageUrl(data.imageUrl);

        // Call the Firefly API to upload image to Fireflu
        const fireflyResponse = await fetch("http://localhost:3000/upload_image", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            imageUrl: data.imageUrl,
          }),
        });

        if (fireflyResponse.ok) {
          const fireflyData = await fireflyResponse.json();
          console.log("Image sent to Firefly API for processing:", fireflyData);
          setUploadedImageId(fireflyData.image_id, file);
        } else {
          console.error("Failed to send image to Firefly API");
        }
      } else {
        setUploadSuccess(false);
        console.error("Image upload failed");
      }
    } catch (error) {
      setUploadSuccess(false);
      console.error("Error uploading image:", error);
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <View
      backgroundColor="gray-100"
      padding="size-200"
      borderBottomWidth="thin"
      borderColor="gray-300"
      borderRadius="medium"
      width="90vw"
      marginBottom="size-400"
      marginTop="size-400"
      UNSAFE_style={{
        boxShadow: "0px 4px 10px rgba(0, 0, 0, 0.1)",
        margin: "0 auto",
      }}
    >
      <Flex direction="column" alignItems="center" justifyContent="center" gap="size-200">
        <Heading level={3}>Upload an image</Heading>
        <FileTrigger onSelect={handleFileUpload} accepts={["image/*"]}>
          <Button
            variant="accent"
            UNSAFE_style={{
              backgroundColor: "#C8102E", // AFTIA Red
              color: "white",
            }}
          >
            {isUploading ? "Uploading..." : "Upload an image"}
          </Button>
        </FileTrigger>
        <Text>Click the button to select a file.</Text>
        {uploadSuccess === true && <Text>Image uploaded successfully!</Text>}
        {uploadSuccess === false && <Text color="negative">Failed to upload image.</Text>}
        {errorMessage && <Text color="negative">{errorMessage}</Text>}
      </Flex>
    </View>
  );
}