import { useState } from "react";
import { View, Image, Text, TextField, Button } from "@adobe/react-spectrum";
import useSaveTransformedImage from "../../../hooks/useSaveTransformedImage";

export default function GenerateCustomModelImage({ uploadedImageId, originalImageId }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [prompt, setPrompt] = useState("");

  const { saveTransformedImage, isSaving } = useSaveTransformedImage();

  const generateImage = async () => {
    if (!prompt) {
      setError("Please enter a prompt.");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await fetch("http://localhost:3000/generate_custom_model_image", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(prompt),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(errorText || "Failed to generate image");
      }

      const data = await response.json();

      if (data.image_url) {
        setImageUrl(data.image_url);
      } else {
        setError("Image generation failed: No image URL returned.");
      }
    } catch (error) {
      setError(`Error processing image: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View marginTop="size-400" width="100%" maxWidth="500px" alignSelf="center">
      <TextField label="Enter a prompt" value={prompt} onChange={setPrompt} isRequired />
      {error && <Text align="center" color="negative">{error}</Text>}

      <View marginTop="size-200" alignSelf="center">
        <Button onPress={generateImage} isDisabled={loading}>
          {loading ? "Generating..." : "Generate Image"}
        </Button>

          <Button
            onPress={() => saveTransformedImage(imageUrl, originalImageId)}
            variant="secondary"
            marginStart="size-200"
          >
            {"Save Image"}
          </Button>
      </View>
    </View>
  );
}