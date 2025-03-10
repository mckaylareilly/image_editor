import { useState } from "react";
import { View, Image, Text, TextField, Button, Flex } from "@adobe/react-spectrum";
import ImageUpload from "../ImageUpload";

export default function FillImage({ uploadedImageId, originalImageId }) {
  const [filledImage, setFilledImage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [prompt, setPrompt] = useState("");
  const [maskId, setMaskId] = useState(null);
  const [imageUrl, setImageUrl] = useState(null);

  // Update the maskId when a new image is uploaded through ImageUpload
  const handleMaskUpload = (id) => {
    setMaskId(id);
  };

  const fillImage = async () => {
    if (!maskId || !prompt) {
      setError("Please upload a mask image and provide a prompt.");
      return;
    }

    setLoading(true);
    setError(null);

    // Call the Rails API to fill an image
    try {
      const response = await fetch("http://localhost:3000/fill_image", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          firefly: { mask_id: maskId, source_id: uploadedImageId, prompt },
        }),
      });

      if (!response.ok) throw new Error("Failed to fill image");

      const data = await response.json();

      if (data.filled_image_url) {
        setFilledImage(data.filled_image_url);
      } else {
        setError("Image fill failed.");
      }
    } catch (error) {
      setError(`Error processing image: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const saveImage = async () => {
    if (!filledImage) {
      console.error("No filled image URL to save.");
      return;
    }

    if (!originalImageId) {
      console.error("No original image ID found.");
      return;
    }

    setSaving(true);

    // Call the Rails API to save tranformed image
    try {
      const response = await fetch("http://localhost:3000/transformed_images", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          transformed_image: {
            file: filledImage,
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
      <ImageUpload 
        setImageUrl={setImageUrl} 
        setUploadedImageId={handleMaskUpload} 
        setOriginalImageId={() => {}} 
      />
      <TextField 
        label="Prompt" 
        value={prompt} 
        onChange={setPrompt} 
        isRequired 
      />
      {error && <Text align="center" color="negative">{error}</Text>}
      
      {filledImage && <Image src={filledImage} alt="Filled Image" width="100%" height="auto" objectFit="contain" />}
      
      <View marginTop="size-200" alignSelf="center">
        <Button onPress={fillImage} isDisabled={loading}>
          {loading ? "Filling Image..." : "Fill Image"}
        </Button>
        {filledImage && (
          <Button onPress={saveImage} isDisabled={saving}>
            {saving ? "Saving..." : "Save Image"}
          </Button>
        )}
      </View>
    </View>
  );
}