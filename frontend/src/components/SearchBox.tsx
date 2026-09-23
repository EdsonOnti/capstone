import { Search, Loader2 } from 'lucide-react';
import { useState } from 'react';
import { api } from '../lib/api';
import type { Product } from '../lib/types';

interface SearchBoxProps {
  onResults: (products: Product[]) => void;
  onSearchStart: () => void;
  onSearchEnd: () => void;
}

export function SearchBox({ onResults, onSearchStart, onSearchEnd }: SearchBoxProps) {
  const [query, setQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!query.trim()) return;

    setIsSearching(true);
    setError(null);
    onSearchStart();

    try {
      const result = await api.semanticSearch(query);
      const products = result.results || result.products || [];
      onResults(products);
    } catch (err) {
      console.error('Search error:', err);
      setError('Error en la búsqueda. Intenta de nuevo.');
      onResults([]);
    } finally {
      setIsSearching(false);
      onSearchEnd();
    }
  };

  return (
    <div className="w-full bg-gradient-to-r from-blue-50 to-indigo-50 p-6 rounded-lg border border-blue-200 mb-6">
      <form onSubmit={handleSearch} className="flex gap-2">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Busca productos por descripción, estilo, material... (ej: 'abrigado para el frío')"
            className="w-full pl-10 pr-4 py-3 border border-blue-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>
        <button
          type="submit"
          disabled={isSearching}
          className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 transition-colors font-medium flex items-center gap-2 whitespace-nowrap"
        >
          {isSearching ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              Buscando...
            </>
          ) : (
            <>
              <Search className="w-4 h-4" />
              Buscar
            </>
          )}
        </button>
      </form>
      {error && (
        <p className="text-red-600 text-sm mt-2">❌ {error}</p>
      )}
      <p className="text-gray-600 text-xs mt-2">💡 Búsqueda semántica con IA - encuentra lo que buscas por concepto, no solo por palabras exactas</p>
    </div>
  );
}
