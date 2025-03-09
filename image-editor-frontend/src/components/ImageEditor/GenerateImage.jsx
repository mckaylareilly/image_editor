import { useState } from "react";
import { View, Image, Text, TextField, Button } from "@adobe/react-spectrum";

export default function GenerateImage({ uploadedImageId, originalImageId }) {
  const [generatedImage, setGeneratedImage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [prompt, setPrompt] = useState("");

  const generateImage = async () => {
    if (!prompt) {
      setError("Please enter a prompt.");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await fetch("http://localhost:3000/generate_image", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ firefly: { prompt, firefly_image_id: uploadedImageId } }),
      });

      if (!response.ok) throw new Error("Failed to generate image");

      const data = await response.json();

      if (data.outputs[0].image.url) {
        setGeneratedImage(data.outputs[0].image.url);
      } else {
        setError("Image generation failed.");
      }
    } catch (error) {
      setError(`Error processing image: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const saveImage = async () => {
    if (!generatedImage) {
        console.error("No generated image URL to save.");
        return;
      }
    
      if (!originalImageId) {
        console.error("No original image ID found.");
        return;
      }

    setSaving(true);
    try {
      const response = await fetch("http://localhost:3000/transformed_images", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            transformed_image: {
              file: generatedImage,  
              image_id: originalImageId,
            },
          }),
        });

      if (!response.ok) throw new Error("Failed to save image");

      alert("Image saved successfully!");
    } catch (error) {
      setError(`Error saving image: ${error.message}`);
    } finally {
      setSaving(false);
    }
  };

  return (
    <View marginTop="size-400" width="100%" maxWidth="500px" alignSelf="center">
      <TextField label="Enter a prompt" value={prompt} onChange={setPrompt} isRequired />
      {error && <Text align="center" color="negative">{error}</Text>}
      
      {generatedImage && <Image src={generatedImage} alt="Generated Image" width="100%" height="auto" objectFit="contain" />}
      
      <View marginTop="size-200" alignSelf="center">
        <Button onPress={generateImage} isDisabled={loading}>{loading ? "Generating..." : "Generate Image"}</Button>
        {generatedImage && <Button onPress={saveImage} isDisabled={saving}>{saving ? "Saving..." : "Save Image"}</Button>}
      </View>
    </View>
  );
}