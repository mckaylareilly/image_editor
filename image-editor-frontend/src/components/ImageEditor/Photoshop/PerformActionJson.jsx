import { useState } from "react";
import { View, Button, Flex } from "@adobe/react-spectrum";
import useSaveTransformedImage from "../../../hooks/useSaveTransformedImage";

export default function PerformActionJson({ imageUrl, setImageUrl, inputImageFile, originalImageId }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const { saveTransformedImage } = useSaveTransformedImage();

  const handlePerformActions = async () => {
    if (!imageUrl) {
      setError("Please upload an image file.");
      return;
    }

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append("input_url", imageUrl);

    try {
      const res = await fetch("http://localhost:3000/perform_action_json", {
        method: "POST",
        body: formData,
        credentials: 'include',
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Error performing Photoshop action.");
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
        {error && <Text align="center" color="negative">{error}</Text>}
        
        <Button onPress={handlePerformActions} isDisabled={loading}>
          {loading ? "Processing..." : "Perform Actions"}
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