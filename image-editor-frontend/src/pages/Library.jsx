import { useState, useEffect } from "react";
import { View, Flex, Image, Text } from "@adobe/react-spectrum";

export default function Library() {
  const [pairedImages, setPairedImages] = useState([]);  
  const [loading, setLoading] = useState(true);  

  // Call the transformed images API to index transformed images and their associated original image
  useEffect(() => {
    const fetchTransformedImages = async () => {
      try {
        const response = await fetch("http://localhost:3000/transformed_images"); 
        if (response.ok) {
          const data = await response.json();
          setPairedImages(data);  
        } else {
          console.error("Failed to fetch paired images");
        }
      } catch (error) {
        console.error("Error fetching paired images:", error);
      } finally {
        setLoading(false);  
      }
    };

    fetchTransformedImages();
  }, []);

  return (
    <View backgroundColor="gray-200" minHeight="100vh" width="100vw">
      <Flex direction="column" alignItems="center" gap="size-400" width="100%">
        {loading ? (
          <Text>Loading paired images...</Text>
        ) : (
          <Flex direction="row" wrap="wrap" gap="size-400" justifyContent="center" width="100%">
            {pairedImages.map((pair, index) => (
              <Flex key={index} direction="column" alignItems="center" gap="size-100">
                <Image src={pair.original_image_url} alt="Regular Image" width="200px" height="auto" objectFit="contain" />
                <Text>Regular Image</Text>
                <Image src={pair.transformed_image_url} alt="Transformed Image" width="200px" height="auto" objectFit="contain" />
                <Text>Transformed Image</Text>
              </Flex>
            ))}
          </Flex>
        )}
      </Flex>
    </View>
  );
}