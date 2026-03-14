import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Persist — AI Impact Measurement",
  description:
    "Go beyond AI adoption. See where work happens, and prove the impact.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
