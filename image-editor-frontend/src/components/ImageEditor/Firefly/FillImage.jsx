import { useState } from "react";
import { View, Image, Text, TextField, Button, Flex } from "@adobe/react-spectrum";
import ImageUpload from "../../ImageUpload";
import useSaveTransformedImage from "../../../hooks/useSaveTransformedImage";

export default function FillImage({ originalImageId, setImageUrl, imageUrl, maskUrl }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [prompt, setPrompt] = useState("");
  
  const { saveTransformedImage, isSaving } = useSaveTransformedImage();

  const fillImage = async () => {
    if (!prompt || !imageUrl || !maskUrl) {
      setError("Please upload a mask image, and a base image, and provide a prompt.");
      return;
    }

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append("input_url", imageUrl);
    formData.append("mask_url", maskUrl);
    formData.append("prompt", prompt);


    // Call the Rails API to fill an image
    try {
      const response = await fetch("http://localhost:3000/fill_image", {
        method: "POST",
        body: formData,
        credentials: "include"
      });

      if (!response.ok) throw new Error("Failed to fill image");

      const data = await response.json();

      if (data.image_url) {
        setImageUrl(data.image_url);
      } else {
        setError("Image fill failed.");
      }
    } catch (error) {
      setError(`Error processing image: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View marginTop="size-400" width="100%" maxWidth="500px" alignSelf="center">
      <TextField 
        label="Prompt" 
        value={prompt} 
        onChange={setPrompt} 
        isRequired 
      />
      {error && <Text align="center" color="negative">{error}</Text>}
            
      <View marginTop="size-200" alignSelf="center">
        <Button onPress={fillImage} isDisabled={loading}>
          {loading ? "Filling Image..." : "Fill Image"}
        </Button>
   
          <Button onPress={() => saveTransformedImage(imageUrl, originalImageId)}>
            {"Save Image"}
          </Button>
      </View>
    </View>
  );
}