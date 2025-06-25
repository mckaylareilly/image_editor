import { useState } from "react";
import { View, Image, Text, TextField, Button } from "@adobe/react-spectrum";
import useSaveTransformedImage from "../../../hooks/useSaveTransformedImage";

export default function ExpandImage({ originalImageId, setImageUrl, imageUrl }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [width, setWidth] = useState("");
  const [height, setHeight] = useState("");

  const { saveTransformedImage, isSaving } = useSaveTransformedImage();
  

  const expandImage = async () => {
    if (!width || !height || !imageUrl) {
      setError("Please enter both width and height, and make sure you uploaded an image");
      return;
    }

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append("input_url", imageUrl);
    formData.append("width", width);
    formData.append("height", height);

    // Call the Rails API to expand an image
    try {
      const response = await fetch("http://localhost:3000/expand_image", {
        method: "POST",
          body: formData,
        credentials: "include",
      });

      if (!response.ok) throw new Error("Failed to expand image");

      const data = await response.json();

      if (data.image_url) {
        setImageUrl(data.image_url);
      } else {
        setError("Image expansion failed.");
      }
    } catch (error) {
      setError(`Error processing image: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View marginTop="size-400" width="100%" maxWidth="500px" alignSelf="center">
      <TextField label="Width" value={width} onChange={setWidth} isRequired />
      <TextField label="Height" value={height} onChange={setHeight} isRequired />
      {error && <Text align="center" color="negative">{error}</Text>}
            
      <View marginTop="size-200" alignSelf="center">
        <Button onPress={expandImage} isDisabled={loading}>{loading ? "Expanding..." : "Expand Image"}</Button>
        <Button onPress={() => saveTransformedImage(imageUrl, originalImageId)}>{"Save Image"}</Button>
      </View>
    </View>
  );
}