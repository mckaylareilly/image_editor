import { useState } from "react";
import { View, Text, TextField, Button, Image, Flex } from "@adobe/react-spectrum";
import useSaveTransformedImage from "../../../hooks/useSaveTransformedImage";

export default function RemoveBackground({ imageUrl, setImageUrl, originalImageId }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const { saveTransformedImage } = useSaveTransformedImage();

  const handleRemoveBackground = async () => {
    if (!imageUrl) {
      setError("Please upload an image file.");
      return;
    }

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append("input_url", imageUrl);

    try {
      const res = await fetch("http://localhost:3000/remove_background", {
        method: "POST",
        body: formData,
        credentials: 'include',
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Error performing Photoshop Remove Background.");
      } else {
        setImageUrl(data.output_url);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!imageUrl || !originalImageId) return;
    await saveTransformedImage(imageUrl, originalImageId);
  };

  return (
    <View width="100%" marginTop="size-400">
      <Flex direction="column" alignItems="center" gap="size-200" maxWidth="500px" marginX="auto">
        {error && <Text color="negative">{error}</Text>}


        <Button onPress={handleRemoveBackground} isDisabled={loading}>
          {loading ? "Processing..." : "Remove Background"}
        </Button>

          <View marginTop="size-400" alignSelf="center">
            <Button
              onPress={handleSave}
              marginTop="size-200"
            >
              {"Save Image"}
            </Button>
          </View>
      </Flex>
    </View>
  );
}