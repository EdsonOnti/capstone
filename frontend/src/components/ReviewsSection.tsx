import React, { useState } from 'react';
import { MessageCircle, Send, AlertCircle, TrendingUp } from 'lucide-react';
import { api } from '../lib/api';

interface Review {
  id: string;
  text: string;
  timestamp: string;
}

interface ReviewsSectionProps {
  productId: string;
  reviews?: Review[];
  sentiment?: string;
  sentimentCounts?: Record<string, number>;
  onReviewAdded?: (reviews: Review[]) => void;
}

export function ReviewsSection({
  productId,
  reviews = [],
  sentiment,
  sentimentCounts,
  onReviewAdded,
}: ReviewsSectionProps) {
  const [reviewText, setReviewText] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleAddReview = async () => {
    if (!reviewText.trim()) {
      setError('Escribe una reseña primero');
      return;
    }

    setIsSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const result = await api.addReview(productId, reviewText);
      setReviewText('');
      setSuccess('✅ Reseña agregada');
      onReviewAdded?.(result.reviews);
      setTimeout(() => setSuccess(null), 2000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al agregar reseña');
    } finally {
      setIsSubmitting(false);
    }
  };



  return (
    <div className="space-y-6">
      {/* Reviews Input */}
      <div className="bg-white p-4 rounded-lg border border-gray-200">
        <div className="flex items-center gap-2 mb-4">
          <MessageCircle className="w-5 h-5 text-blue-600" />
          <h3 className="font-semibold text-gray-900">Reseñas de clientes</h3>
        </div>

        <div className="space-y-3">
          <textarea
            value={reviewText}
            onChange={(e) => setReviewText(e.target.value)}
            placeholder="Escribe una reseña... (ej: 'Excelente producto, muy buena calidad')"
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            rows={3}
            disabled={isSubmitting}
          />

          <button
            onClick={handleAddReview}
            disabled={isSubmitting || !reviewText.trim()}
            className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition"
          >
            {isSubmitting ? (
              <>
                <div className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full" />
                Enviando...
              </>
            ) : (
              <>
                <Send className="w-4 h-4" />
                Enviar reseña
              </>
            )}
          </button>
        </div>

        {error && (
          <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-md flex items-start gap-2">
            <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {success && (
          <div className="mt-3 p-3 bg-green-50 border border-green-200 rounded-md text-sm text-green-600">
            {success}
          </div>
        )}
      </div>


      {/* Reviews List */}
      {reviews.length > 0 && (
        <div className="bg-white p-4 rounded-lg border border-gray-200">
          <h3 className="font-semibold text-gray-900 mb-4">
            Historial de reseñas ({reviews.length})
          </h3>
          <div className="space-y-3">
            {reviews.map((review) => (
              <div key={review.id} className="p-3 bg-gray-50 rounded-md border border-gray-100">
                <p className="text-sm text-gray-900">{review.text}</p>
                <p className="text-xs text-gray-500 mt-2">
                  {new Date(review.timestamp).toLocaleDateString('es-ES', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
