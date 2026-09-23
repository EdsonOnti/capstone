import { X, MessageCircle, TrendingUp, AlertCircle, Sparkles } from 'lucide-react';
import { useState, useEffect } from 'react';
import type { Product } from '../lib/types';
import { api } from '../lib/api';
import { ReviewsSection } from './ReviewsSection';

interface ProductDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  product?: Product;
}

export function ProductDetailsModal({ isOpen, onClose, product }: ProductDetailsModalProps) {
  const [reviews, setReviews] = useState<any[]>([]);
  const [sentiment, setSentiment] = useState<string | undefined>();
  const [sentimentCounts, setSentimentCounts] = useState<Record<string, number>>();
  const [currentProduct, setCurrentProduct] = useState<Product | undefined>(product);

  useEffect(() => {
    if (product && isOpen) {
      // Fetch fresh product data to get latest AI fields
      api.getProduct(product.productId).then(freshProduct => {
        setCurrentProduct(freshProduct);
        setReviews(freshProduct.reviews || []);
        setSentiment(freshProduct.reviewSentiment);
        setSentimentCounts(freshProduct.reviewSentimentCounts);
      }).catch(err => {
        console.error('Error fetching product:', err);
        // Fallback to original product if fetch fails
        setCurrentProduct(product);
        setReviews(product.reviews || []);
        setSentiment(product.reviewSentiment);
        setSentimentCounts(product.reviewSentimentCounts);
      });
    }
  }, [product, isOpen]);

  if (!isOpen || !currentProduct) return null;

  const displayProduct = currentProduct;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-3xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b sticky top-0 bg-white">
          <h2 className="text-2xl font-bold text-gray-900">
            {displayProduct.name}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="p-6 space-y-6">
          {/* Product Image and Basic Info */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Image */}
            <div className="flex items-center justify-center bg-gray-100 rounded-lg overflow-hidden">
              <img
                src={displayProduct.imageUrl}
                alt={displayProduct.name}
                className="w-full h-96 object-cover"
              />
            </div>

            {/* Product Details */}
            <div className="space-y-4">
              <div>
                <p className="text-gray-500 text-sm">Categoría</p>
                <p className="text-gray-900 font-medium">{displayProduct.category}</p>
              </div>

              <div>
                <p className="text-gray-500 text-sm">Descripción</p>
                <p className="text-gray-900">{displayProduct.description}</p>
              </div>

              <div>
                <p className="text-gray-500 text-sm">Precio</p>
                <p className="text-3xl font-bold text-blue-600">
                  ${displayProduct.price.toFixed(2)}
                </p>
              </div>

              <div>
                <p className="text-gray-500 text-sm">Stock disponible</p>
                <p className={`font-semibold ${displayProduct.stock > 0 ? 'text-green-600' : 'text-red-600'}`}>
                  {displayProduct.stock > 0 ? `${displayProduct.stock} unidades` : 'Agotado'}
                </p>
              </div>

              {/* AI Labels */}
              {displayProduct.aiLabels && displayProduct.aiLabels.length > 0 && (
                <div>
                  <p className="text-gray-500 text-sm mb-2">Etiquetas AI</p>
                  <div className="flex flex-wrap gap-2">
                    {displayProduct.aiLabels.map((label, i) => (
                      <span
                        key={i}
                        className="px-3 py-1 bg-purple-100 text-purple-700 rounded-full text-xs font-medium"
                      >
                        {label}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* AI Generated Description */}
              {displayProduct.aiDescription && (
                <div className="p-4 bg-gradient-to-br from-indigo-50 to-purple-50 rounded-lg border border-indigo-100">
                  <div className="flex items-center gap-2 mb-2">
                    <Sparkles className="w-4 h-4 text-indigo-600" />
                    <p className="text-gray-700 text-sm font-semibold">Descripción IA</p>
                  </div>
                  <p className="text-gray-700 text-sm leading-relaxed">
                    {displayProduct.aiDescription}
                  </p>
                </div>
              )}

              {/* Moderation Status */}
              {displayProduct.moderationStatus && (
                <div className={`p-3 rounded-md text-sm font-medium ${
                  displayProduct.moderationStatus === 'APPROVED'
                    ? 'bg-green-50 text-green-700'
                    : 'bg-yellow-50 text-yellow-700'
                }`}>
                  {displayProduct.moderationStatus === 'APPROVED'
                    ? '✅ Imagen aprobada'
                    : '⚠️ Imagen contiene contenido sensible'}
                </div>
              )}

              {/* Add to Cart Button */}
              <button
                disabled={displayProduct.stock === 0}
                className={`w-full py-3 rounded-lg font-semibold transition-colors ${
                  displayProduct.stock === 0
                    ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                    : 'bg-blue-600 text-white hover:bg-blue-700'
                }`}
              >
                {displayProduct.stock === 0 ? 'Agotado' : 'Agregar al Carrito'}
              </button>
            </div>
          </div>

          {/* Reviews Section */}
          <div className="border-t pt-6">
            <ReviewsSection
              productId={displayProduct.productId}
              reviews={reviews}
              sentiment={sentiment}
              sentimentCounts={sentimentCounts}
              onReviewAdded={(newReviews) => setReviews(newReviews)}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
