import { useState } from "react";
import { View, Button, Flex } from "@adobe/react-spectrum";

export default function CreateMask({ setMaskUrl, imageUrl }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleCreateMask = async () => {
    if (!imageUrl) {
      setError("Please upload an image file.");
      return;
    }

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append("input_url", imageUrl);

    try {
      const res = await fetch("http://localhost:3000/create_mask", {
        method: "POST",
        body: formData,
        credentials: 'include',
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Error performing Photoshop Remove Background.");
      } else {
        setMaskUrl(data.output_url);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View width="100%" marginTop="size-400">
      <Flex direction="column" alignItems="center" gap="size-200" maxWidth="500px" marginX="auto">
        {error && <Text align="center" color="negative">{error}</Text>}
        
        <Button onPress={handleCreateMask} isDisabled={loading}>
          {loading ? "Processing..." : "Create Mask"}
        </Button>
      </Flex>
    </View>
  );
}