import React from 'react';
import { View, Image, Flex, Heading, Tabs, TabList, TabPanels, Item } from "@adobe/react-spectrum";
import GenerateImage from "./GenerateImage";
import FillImage from "./FillImage";
import ExpandImage from "./ExpandImage"; // Assuming you have these components

export default function ImageEditor({ imageUrl, uploadedImageId, originalImageId }) {
  // Setup tabs for the ImageEditor components
  const tabs = [
    {
      id: 1,
      name: 'Generate an Image from a Reference Photo',
      children: <GenerateImage uploadedImageId={uploadedImageId} originalImageId={originalImageId} />
    },
    {
      id: 2,
      name: 'Fill Background',
      children: <FillImage uploadedImageId={uploadedImageId} originalImageId={originalImageId} />
    },
    {
      id: 3,
      name: 'Expand Background',
      children: <ExpandImage uploadedImageId={uploadedImageId} originalImageId={originalImageId} />
    }
  ];

  const [tabId, setTabId] = React.useState(1);

  return (
    <View
      marginTop="size-400"
      backgroundColor="gray-100"
      padding="size-200"
      borderBottomWidth="thin"
      borderColor="gray-300"
      borderRadius="medium"
      width="90vw"
      marginBottom="size-400"
      UNSAFE_style={{
        boxShadow: "0px 4px 10px rgba(0, 0, 0, 0.1)",
        margin: "0 auto",
      }}
    >
      <Flex direction="column" alignItems="center" justifyContent="center" gap="size-200">
        <Heading level={3}>Edit an Image</Heading>

        <Tabs
          aria-label="Image Manipulation Options"
          items={tabs}
          onSelectionChange={setTabId}
        >
          <TabList>
            {(item) => (
              <Item key={item.id}>
                {item.name}
              </Item>
            )}
          </TabList>

          <TabPanels>
            {(item) => (
              <Item key={item.id}>
                {item.children}
              </Item>
            )}
          </TabPanels>
        </Tabs>

        <Image
          src={imageUrl}
          alt="Uploaded Image"
          width="100%"
          height="auto"
          objectFit="contain"
        />
      </Flex>
    </View>
  );
}