import { useState } from "react";
import { View, Image, Text, TextField, Button } from "@adobe/react-spectrum";

export default function ExpandImage({ uploadedImageId, originalImageId }) {
  const [expandedImage, setExpandedImage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [width, setWidth] = useState("");
  const [height, setHeight] = useState("");

  const expandImage = async () => {
    if (!width || !height) {
      setError("Please enter both width and height.");
      return;
    }

    setLoading(true);
    setError(null);

    // Call the Rails API to expand an image
    try {
      const response = await fetch("http://localhost:3000/expand_image", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ firefly: { width, height, firefly_image_id: uploadedImageId } }),
      });

      if (!response.ok) throw new Error("Failed to expand image");

      const data = await response.json();

      if (data.expanded_image_url) {
        setExpandedImage(data.expanded_image_url);
      } else {
        setError("Image expansion failed.");
      }
    } catch (error) {
      setError(`Error processing image: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const saveImage = async () => {
    if (!expandedImage) {
      console.error("No expanded image URL to save.");
      return;
    }

    if (!originalImageId) {
      console.error("No original image ID found.");
      return;
    }

    setSaving(true);
    // Call the Rails API to save the transformed image
    try {
      const response = await fetch("http://localhost:3000/transformed_images", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          transformed_image: {
            file: expandedImage,  
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
      <TextField label="Width" value={width} onChange={setWidth} isRequired />
      <TextField label="Height" value={height} onChange={setHeight} isRequired />
      {error && <Text align="center" color="negative">{error}</Text>}
      
      {expandedImage && <Image src={expandedImage} alt="Expanded Image" width="100%" height="auto" objectFit="contain" />}
      
      <View marginTop="size-200" alignSelf="center">
        <Button onPress={expandImage} isDisabled={loading}>{loading ? "Expanding..." : "Expand Image"}</Button>
        {expandedImage && <Button onPress={saveImage} isDisabled={saving}>{saving ? "Saving..." : "Save Image"}</Button>}
      </View>
    </View>
  );
}