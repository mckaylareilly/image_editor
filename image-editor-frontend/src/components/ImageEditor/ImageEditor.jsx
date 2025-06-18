import React from "react";
import { View, Image, Flex, Heading, Tabs, TabList, TabPanels, Item, Button } from "@adobe/react-spectrum";
import GenerateImage from "./Firefly/GenerateImage";
import FillImage from "./Firefly/FillImage";
import ExpandImage from "./Firefly/ExpandImage";
import PerformActions from "./Photoshop/PerformActions";
import PerformActionJson from './Photoshop/PerformActionJson'
import GenerateCustomModelImage from "./Firefly/GenerateCustomModelImage";
import RemoveBackground from "./Photoshop/RemoveBackground";
import CreateMask from "./Photoshop/CreateMask";

export default function ImageEditor({ imageUrl, setImageUrl, uploadedImageId, originalImageId, imageFile }) {
  const [parentTab, setParentTab] = React.useState("firefly");
  const [fireflyTab, setFireflyTab] = React.useState("generate");
  const [photoshopTab, setPhotoshopTab] = React.useState('apply'); 


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

        {/* Parent Tabs: Firefly vs Photoshop */}
        <Tabs
          aria-label="Image Editing Categories"
          selectedKey={parentTab}
          onSelectionChange={setParentTab}
        >
          <TabList>
            <Item key="firefly">Firefly</Item>
            <Item key="photoshop">Photoshop</Item>
          </TabList>

          <TabPanels>
  {/* Firefly Tab Panel with Sub-tabs */}
  <Item key="firefly">
    <Tabs
      aria-label="Firefly Tools"
      selectedKey={fireflyTab}
      onSelectionChange={setFireflyTab}
    >
      <TabList>
        <Item key="generate">Generate from Reference</Item>
        <Item key="fill">Fill Background</Item>
        <Item key="expand">Expand Background</Item>
        <Item key="generate-custom">Generate Image from Custom Model</Item>
      </TabList>

      <TabPanels>
        <Item key="generate">
          <GenerateImage setImageUrl={setImageUrl} imageUrl={imageUrl} uploadedImageId={uploadedImageId} originalImageId={originalImageId} />
        </Item>
        <Item key="fill">
          <FillImage setImageUrl={setImageUrl} imageUrl={imageUrl} uploadedImageId={uploadedImageId} originalImageId={originalImageId} />
        </Item>
        <Item key="expand">
          <ExpandImage setImageUrl={setImageUrl} imageUrl={imageUrl} uploadedImageId={uploadedImageId} originalImageId={originalImageId} />
        </Item>
        <Item key="generate-custom">
          <GenerateCustomModelImage setImageUrl={setImageUrl} imageUrl={imageUrl} uploadedImageId={uploadedImageId} originalImageId={originalImageId} />
        </Item>
      </TabPanels>
    </Tabs>
  </Item>

  {/* Photoshop Tab Panel with Sub-tabs */}
  <Item key="photoshop">
    <Tabs
      aria-label="Photoshop Tools"
      selectedKey={photoshopTab}
      onSelectionChange={setPhotoshopTab}
    >
      <TabList>
        <Item key="apply">Apply Actions</Item>
        <Item key="apply-json">Apply Actions JSON</Item>
        <Item key="remove_background">Remove Background</Item>
        <Item key="create_mask">Create Mask</Item>

      </TabList>

      <TabPanels>
        <Item key="apply">
          <PerformActions setImageUrl={setImageUrl} imageUrl={imageUrl} inputImageFile={imageFile} originalImageId={originalImageId} />
        </Item>
        <Item key="apply-json">
          <PerformActionJson setImageUrl={setImageUrl} imageUrl={imageUrl} inputImageFile={imageFile} originalImageId={originalImageId} />
        </Item>
        <Item key="remove_background">
          <RemoveBackground setImageUrl={setImageUrl} imageUrl={imageUrl} inputImageFile={imageFile} originalImageId={originalImageId} />
        </Item>
        <Item key="create_mask">
          <CreateMask setImageUrl={setImageUrl} imageUrl={imageUrl} inputImageFile={imageFile} originalImageId={originalImageId} />
        </Item>
      </TabPanels>
    </Tabs>
  </Item>
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