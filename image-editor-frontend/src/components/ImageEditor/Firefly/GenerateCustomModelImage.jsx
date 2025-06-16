import { useState } from "react";
import { View, Image, Text, TextField, Button } from "@adobe/react-spectrum";
import useSaveTransformedImage from "../../../hooks/useSaveTransformedImage";

export default function GenerateCustomModelImage({ uploadedImageId, originalImageId }) {
  const [generatedImage, setGeneratedImage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
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
        body: JSON.stringify({ firefly: { prompt } }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(errorText || "Failed to generate image");
      }

      const data = await response.json();

      if (data.image_url) {
        setGeneratedImage(data.image_url);
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

      {generatedImage && (
        <Image
          src={generatedImage}
          alt="Generated Image"
          width="100%"
          height="auto"
          objectFit="contain"
        />
      )}

      <View marginTop="size-200" alignSelf="center">
        <Button onPress={generateImage} isDisabled={loading}>
          {loading ? "Generating..." : "Generate Image"}
        </Button>

        {generatedImage && (
          <Button
            onPress={() => saveTransformedImage(generatedImage, originalImageId)}
            isDisabled={saving || isSaving}
            variant="secondary"
            marginStart="size-200"
          >
            {saving || isSaving ? "Saving..." : "Save Image"}
          </Button>
        )}
      </View>
    </View>
  );
}